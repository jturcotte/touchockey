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

#ifndef HTTPSERVER_H
#define HTTPSERVER_H

#include <QNetworkRequest>
#include <QTcpServer>
#include <memory>

class HttpConnection : public QObject {
    Q_OBJECT
public:
    HttpConnection(QTcpSocket *socket);
    ~HttpConnection();

    QTcpSocket *takeSocket() { return m_socket.release(); }
    QByteArray method() const { return m_method; }
    QNetworkRequest request() const { return m_request; }
    QByteArray body() const { return m_buffer; }

signals:
    void requestReady();

private slots:
    void onReadyRead();

private:
    enum class State {
        ParsingRequestLine,
        ParsingHeaders,
        Body
    } state = State::ParsingRequestLine;
    void processRequestLine(const QByteArray &line);
    void processHeaderLine(const QByteArray &line);

    std::unique_ptr<QTcpSocket> m_socket;
    QByteArray m_method;
    QNetworkRequest m_request;
    QByteArray m_buffer;
};

class HttpServer : public QTcpServer {
    Q_OBJECT
public:
    HttpServer();

signals:
    void normalHttpRequest(const QByteArray &method, const QNetworkRequest &request, const QByteArray &body, QTcpSocket *connection);

private slots:
    void onNewConnection();
    void onRequestReady();
};

#endif
