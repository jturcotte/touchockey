// The MIT License (MIT)
//
// Copyright (c) 2015 Jocelyn Turcotte
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "gameserver.h"
#include "QtWebSockets/QWebSocketServer"
#include "QtWebSockets/QWebSocket"
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMimeDatabase>
#include <QNetworkCookie>
#include <QPoint>
#include <QStandardPaths>
#include <QTcpSocket>
#include <QUuid>

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
    QFile file(QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/playerinfo.json");
    if (file.open(QFile::ReadOnly)) {
        const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
        for (auto i = root.begin(); i != root.end(); ++i)
            m_infoMap[i.key().toLatin1()] = i.value().toObject();
    }
}

void PlayerInfoDb::save() const
{
    QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!dataDir.exists())
        dataDir.mkpath(".");

    QFile file(dataDir.filePath("playerinfo.json"));
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
    } else {
        qWarning("ERROR: Could not listen for HTTP connections on port %d", port);
        qApp->quit();
    }

    if (m_wsServer->listen(QHostAddress::Any, 12345)) {
        qDebug() << "WebSocket Server listening on port" << 12345;
        connect(m_wsServer.get(), &QWebSocketServer::newConnection, this, &GameServerImpl::onNewConnection);
    } else {
        qWarning("ERROR: Could not listen for WebSockets connections on port %d", 12345);
        qApp->quit();
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

    auto player = new PlayerModel{socket};
    player->moveToThread(m_pub->thread());
    connect(player, SIGNAL(vibrate(int)), SLOT(onPlayerVibrate(int)));
    m_socketPlayerMap[socket] = player;
    emit m_pub->playerConnected(qVariantFromValue(player));
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

void GameServerImpl::onPlayerVibrate(int milliseconds)
{
    QString jsonMsg = QStringLiteral("{\"type\":\"vibrate\",\"ms\":%1}").arg(milliseconds);
    static_cast<PlayerModel *>(sender())->socket->sendTextMessage(jsonMsg);
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

        path.prepend(":/client");
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
