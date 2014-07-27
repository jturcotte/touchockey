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
#include <QPoint>
#include <QJsonDocument>
#include <QJsonObject>

QT_USE_NAMESPACE

GameServer::GameServer(quint16 port, QObject *parent) :
    QObject(parent),
    m_wsServer(nullptr),
    m_clients()
{
    m_wsServer = new QWebSocketServer(QStringLiteral("Game Server"),
                                              QWebSocketServer::NonSecureMode,
                                              this);
    if (m_wsServer->listen(QHostAddress::Any, port))
    {
        qDebug() << "Game Server listening on port" << port;
        connect(m_wsServer, &QWebSocketServer::newConnection,
                this, &GameServer::onNewConnection);
    }
}

GameServer::~GameServer()
{
    m_wsServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}

void GameServer::onNewConnection()
{
    QWebSocket *pSocket = m_wsServer->nextPendingConnection();

    connect(pSocket, &QWebSocket::textMessageReceived, this, &GameServer::processMessage);
    connect(pSocket, &QWebSocket::disconnected, this, &GameServer::socketDisconnected);

    m_clients << pSocket;
}

void GameServer::processMessage(const QString &message)
{
    QJsonObject jsonMsg = QJsonDocument::fromJson(message.toLatin1()).object();

    emit playerMoved(QPoint(jsonMsg.value("x").toInt(), jsonMsg.value("y").toInt()));
    // QWebSocket *pSender = qobject_cast<QWebSocket *>(sender());
    // Q_FOREACH (QWebSocket *pClient, m_clients)
    // {
    //     if (pClient != pSender) //don't echo message back to sender
    //     {
    //         pClient->sendTextMessage(message);
    //     }
    // }
}

void GameServer::socketDisconnected()
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient)
    {
        m_clients.removeAll(pClient);
        pClient->deleteLater();
    }
}
