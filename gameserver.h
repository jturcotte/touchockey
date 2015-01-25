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

#ifndef GAMESERVER_H
#define GAMESERVER_H

#include <QByteArray>
#include <QHash>
#include <QObject>
#include <QThread>
#include <memory>
#include <qqml.h>

#include "httpserver.h"

QT_FORWARD_DECLARE_CLASS(QTcpSocket)
QT_FORWARD_DECLARE_CLASS(QNetworkRequest)
QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)

class PlayerModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name MEMBER name NOTIFY nameChanged FINAL)
public:
    QWebSocket *socket;
    QString name;

    PlayerModel(QWebSocket *socket) : socket(socket) { }

signals:
    void nameChanged();
    void touchStart();
    void touchMove(const QVariant &x, const QVariant &y, const QVariant &time);
    void touchEnd();

    void vibrate(int milliseconds);
};

class GameServer : public QThread {
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

class PlayerInfoDb {
public:
    PlayerInfoDb();
    QJsonObject playerInfo(const QByteArray &playerId) const;
    void setPlayerInfo(const QByteArray &playerId, const QJsonObject &data);

private:
    void load();
    void save() const;
    QHash<QByteArray, QJsonObject> m_infoMap;
};

class GameServerImpl : public QObject {
    Q_OBJECT
public:
    GameServerImpl(GameServer *pub, quint16 port);
    ~GameServerImpl();

private slots:
    void onNewConnection();
    void processMessage(const QString &message);
    void socketDisconnected();
    void onPlayerVibrate(int milliseconds);
    void handleNormalHttpRequest(const QByteArray &method, const QNetworkRequest &request, const QByteArray &body, QTcpSocket *connection);

private:
    GameServer *m_pub;
    std::unique_ptr<HttpServer> m_httpServer;
    std::unique_ptr<QWebSocketServer> m_wsServer;
    QHash<QWebSocket *, PlayerModel *> m_socketPlayerMap;
    PlayerInfoDb m_playerInfoDb;
};

QML_DECLARE_TYPE(PlayerModel)

#endif //GAMESERVER_H
