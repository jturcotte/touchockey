/****************************************************************************
**
** Copyright (C) 2014 Kurt Pattyn <pattyn.kurt@gmail.com>.
** Contact: http://www.qt-project.org/legal
**
** This file is part of the QtWebSockets module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/
#include "gameserver.h"
#include "QtWebSockets/QWebSocketServer"
#include "QtWebSockets/QWebSocket"
#include <QtCore/QDebug>
#include <QFile>
#include <QUuid>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMimeDatabase>
#include <QNetworkCookie>
#include <QPoint>
#include <QTcpSocket>

GameServer::GameServer(quint16 port, QObject *parent)
    : QThread(parent)
    , m_port(port)
{
    start();
}

GameServer::~GameServer()
{
    quit();
    wait();
}

void GameServer::run()
{
    GameServerImpl impl(this, m_port);
    QThread::run();
}

PlayerInfoDb::PlayerInfoDb()
{
    load();
}

QJsonObject PlayerInfoDb::playerInfo(const QByteArray &playerId) const
{
    return m_infoMap.value(playerId);
}

void PlayerInfoDb::setPlayerInfo(const QByteArray &playerId, const QJsonObject &data)
{
    m_infoMap[playerId] = data;
    save();
}

void PlayerInfoDb::load()
{
    QFile file("playerinfo.json");
    if (file.open(QFile::ReadOnly)) {
        const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
        for (auto i = root.begin(); i != root.end(); ++i)
            m_infoMap[i.key().toLatin1()] = i.value().toObject();
    }
}

void PlayerInfoDb::save() const
{
    QFile file("playerinfo.json");
    if (file.open(QFile::WriteOnly)) {
        QJsonObject root;
        for (auto i = m_infoMap.begin(); i != m_infoMap.end(); ++i)
            root[i.key()] = i.value();
        file.write(QJsonDocument(root).toJson());
    }
}

GameServerImpl::GameServerImpl(GameServer *pub, quint16 port)
    : m_pub(pub)
    , m_httpServer(new HttpServer)
    , m_wsServer(new QWebSocketServer(QStringLiteral("Game Server"), QWebSocketServer::NonSecureMode))
{
    if (m_httpServer->listen(QHostAddress::Any, port)) {
        qDebug() << "HTTP Server listening on port" << port;
        connect(m_httpServer.get(), &HttpServer::normalHttpRequest, this, &GameServerImpl::handleNormalHttpRequest);
    }
    if (m_wsServer->listen(QHostAddress::Any, 12345)) {
        qDebug() << "WebSocket Server listening on port" << 12345;
        connect(m_wsServer.get(), &QWebSocketServer::newConnection, this, &GameServerImpl::onNewConnection);
    }
}

GameServerImpl::~GameServerImpl()
{
    m_wsServer->close();
    for (PlayerModel *player : m_socketPlayerMap)
        player->deleteLater();
    QList<QWebSocket *> sockets = m_socketPlayerMap.keys();
    qDeleteAll(sockets.begin(), sockets.end());
}

void GameServerImpl::onNewConnection()
{
    QWebSocket *socket = m_wsServer->nextPendingConnection();

    connect(socket, &QWebSocket::textMessageReceived, this, &GameServerImpl::processMessage);
    connect(socket, &QWebSocket::disconnected, this, &GameServerImpl::socketDisconnected);

    auto player = new PlayerModel;
    player->moveToThread(m_pub->thread());
    m_socketPlayerMap[socket] = player;
    emit m_pub->playerConnected(qVariantFromValue(player));
}

void GameServerImpl::handleNormalHttpRequest(const QByteArray &method, const QNetworkRequest &request, const QByteArray &body, QTcpSocket *connection)
{
    // qWarning() << method << request.url();
    if (method == "POST") {
        QString path = request.url().path();
        if (path == "/data/userinfo") {
            auto jsonDoc = QJsonDocument::fromJson(body);
            QByteArray playerId;
            QList<QNetworkCookie> cookies = request.header(QNetworkRequest::CookieHeader).value<QList<QNetworkCookie>>();
            for (const QNetworkCookie &cookie : cookies)
                if (cookie.name() == "pid")
                    playerId = cookie.value();

            connection->write("HTTP/1.1 200 OK\r\n");
            connection->write("Connection: close\r\n");
            if (playerId.isNull()) {
                playerId = QUuid::createUuid().toRfc4122().toHex();
                QNetworkCookie pidCookie("pid", playerId);
                pidCookie.setPath(QStringLiteral("/"));
                connection->write("Set-Cookie: " + pidCookie.toRawForm() + "\r\n");
            }
            connection->write("\r\n");

            m_playerInfoDb.setPlayerInfo(playerId, jsonDoc.object());
        } else {
            connection->write("HTTP/1.1 404 Not Found\r\n");
            connection->write("Connection: close\r\n");
            connection->write("\r\n");
        }
    } else if (method == "GET") {
        QString path = request.url().path();
        Q_ASSERT(path.startsWith("/"));
        if (path == "/")
            path = QStringLiteral("/index.html");

        if (path == "/data/userinfo") {
            QByteArray playerId;
            QList<QNetworkCookie> cookies = request.header(QNetworkRequest::CookieHeader).value<QList<QNetworkCookie>>();
            QJsonDocument jsonDoc;
            for (const QNetworkCookie &cookie : cookies)
                if (cookie.name() == "pid")
                    jsonDoc.setObject(m_playerInfoDb.playerInfo(cookie.value()));
            QByteArray jsonData = jsonDoc.toJson(QJsonDocument::Compact);
            connection->write("HTTP/1.1 200 OK\r\n");
            connection->write("Connection: close\r\n");
            connection->write("Content-Type: application/json\r\n");
            connection->write("Content-Length: " + QByteArray::number(jsonData.size()) + "\r\n");
            connection->write("\r\n");
            connection->write(jsonData);
        }

        path.prepend("client");
        QFile file(path);
        if (file.open(QFile::ReadOnly)) {
            connection->write("HTTP/1.1 200 OK\r\n");
            connection->write("Connection: close\r\n");
            connection->write("Content-Type: " + QMimeDatabase().mimeTypeForFile(path).name().toLatin1() + "\r\n");
            connection->write("Content-Length: " + QByteArray::number(file.size()) + "\r\n");
            connection->write("\r\n");
            while (!file.atEnd())
                connection->write(file.read(1024));
        } else {
            connection->write("HTTP/1.1 404 Not Found\r\n");
            connection->write("Connection: close\r\n");
            connection->write("\r\n");
        }
    }
    connection->close();
}

void GameServerImpl::processMessage(const QString &message)
{
    PlayerModel *player = m_socketPlayerMap[static_cast<QWebSocket *>(sender())];
    if (!player)
        return;

    QJsonObject jsonMsg = QJsonDocument::fromJson(message.toLatin1()).object();
    if (jsonMsg.value("type").toString() == QStringLiteral("move"))
        emit player->touchMove(jsonMsg.value("x").toDouble(), jsonMsg.value("y").toDouble(), jsonMsg.value("t").toInt());
    else if (jsonMsg.value("type").toString() == QStringLiteral("start"))
        emit player->touchStart();
    else if (jsonMsg.value("type").toString() == QStringLiteral("end"))
        emit player->touchEnd();
    else if (jsonMsg.value("type").toString() == QStringLiteral("init")) {
        QByteArray playerId = jsonMsg.value("pid").toString().toLatin1();
        player->name = m_playerInfoDb.playerInfo(playerId).value("playerName").toString();
        emit player->nameChanged();
    }
}

void GameServerImpl::socketDisconnected()
{
    QWebSocket *socket = qobject_cast<QWebSocket *>(sender());
    if (socket) {
        PlayerModel *player = m_socketPlayerMap.take(socket);
        emit m_pub->playerDisconnected(qVariantFromValue(player));

        socket->deleteLater();
        player->deleteLater();
    }
}
