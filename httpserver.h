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
