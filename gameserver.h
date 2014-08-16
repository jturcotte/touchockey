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
#ifndef GAMESERVER_H
#define GAMESERVER_H

#include <QByteArray>
#include <QHash>
#include <QObject>
#include <QThread>
#include <qqml.h>

QT_FORWARD_DECLARE_CLASS(QTcpSocket)
QT_FORWARD_DECLARE_CLASS(QNetworkRequest)
QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)

class PlayerModel : public QObject
{
    Q_OBJECT
signals:
    void touchStart();
    void touchMove(const QVariant &x, const QVariant &y, const QVariant &time);
    void touchEnd();
};

class GameServer : public QThread
{
    Q_OBJECT
public:
    GameServer(quint16 port, QObject *parent = nullptr);
    ~GameServer();

protected:
    void run() override;

signals:
    void playerConnected(const QVariant &player);
    void playerDisconnected(const QVariant &player);

private:
    quint16 m_port;
};

class GameServerImpl : public QObject
{
    Q_OBJECT
public:
    GameServerImpl(GameServer *pub, quint16 port);
    ~GameServerImpl();

private slots:
    void onNewConnection();
    void processMessage(const QString &message);
    void socketDisconnected();
    void handleNormalHttpRequest(const QNetworkRequest &request, QTcpSocket *connection);

private:
    GameServer *m_pub;
    QWebSocketServer *m_wsServer;
    QHash<QWebSocket *, PlayerModel *> m_socketPlayerMap;
};

QML_DECLARE_TYPE(PlayerModel)

#endif //GAMESERVER_H
