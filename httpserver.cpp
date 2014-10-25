#include "httpserver.h"

#include <QTcpSocket>

HttpConnection::HttpConnection(QTcpSocket *socket)
    : m_socket(socket)
{
    // FIXME: Handle connection close -> delete
    connect(socket, &QTcpSocket::readyRead, this, &HttpConnection::onReadyRead);
    onReadyRead();
}

HttpConnection::~HttpConnection()
{
}

void HttpConnection::onReadyRead()
{
    while (m_socket->bytesAvailable()) {
        m_buffer += m_socket->read(512);
        if (state < State::Body) {
            int crPos = m_buffer.indexOf('\r');
            while (crPos > -1 && crPos + 1 < m_buffer.size() && m_buffer[crPos + 1] == '\n') {
                QByteArray line = m_buffer.left(crPos);
                m_buffer.remove(0, crPos + 2);
                crPos = m_buffer.indexOf('\r');

                if (line.isEmpty())
                    state = State::Body;
                else if (state == State::ParsingRequestLine)
                    processRequestLine(line);
                else if (state == State::ParsingHeaders)
                    processHeaderLine(line);
            }
        }
        if (state == State::Body) {
            if (m_buffer.size() >= m_request.header(QNetworkRequest::ContentLengthHeader).toLongLong()) {
                emit requestReady();
                return;
            }
        }
    }
}

void HttpConnection::processRequestLine(const QByteArray &line)
{
    Q_ASSERT(state == State::ParsingRequestLine);
    auto tokens = line.split(' ');
    m_method = tokens[0];
    QUrl requestUrl(tokens[1]);
    m_request.setUrl(requestUrl);
    state = State::ParsingHeaders;
}

void HttpConnection::processHeaderLine(const QByteArray &line)
{
    Q_ASSERT(state == State::ParsingHeaders);
    int colonPos = line.indexOf(':');
    QByteArray name = line.left(colonPos);
    QByteArray value = line.mid(colonPos + 2);
    m_request.setRawHeader(name, value);
}

HttpServer::HttpServer()
{
    connect(this, &HttpServer::newConnection, this, &HttpServer::onNewConnection);
}

void HttpServer::onNewConnection()
{
    QTcpSocket *client = nextPendingConnection();
    auto *connection = new HttpConnection(client);
    connect(connection, &HttpConnection::requestReady, this, &HttpServer::onRequestReady);
}

void HttpServer::onRequestReady()
{
    auto *connection = static_cast<HttpConnection*>(sender());
    emit normalHttpRequest(connection->method(), connection->request(), connection->body(), connection->takeSocket());
    delete connection;
}
