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

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml/qtqmlglobal.h>
#include <box2dplugin.h>
#include "gameserver.h"
#include "lightedimageitem.h"
#include "qscreensaver.h"

#include "qqrencode.h"
#include <QImage>
#include <QNetworkInterface>
#include <QQuickImageProvider>

class ImageProvider : public QQuickImageProvider
{
public:
    ImageProvider(QUrl url)
        : QQuickImageProvider(QQuickImageProvider::Image)
        , m_url(std::move(url))
    { }
    QImage requestImage(const QString &id, QSize *size, const QSize& requestedSize) override
    {
        QImage image;
        if (id == QLatin1String("connectQr")) {
            QQREncode encoder;
            encoder.encode(m_url.toString());
            image = encoder.toQImage();
            image.invertPixels();
        }
        if (!requestedSize.isEmpty())
            image = image.scaled(requestedSize);
        if (size)
            *size = image.size();
        return image;
    }

private:
    QUrl m_url;
};

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    QScreenSaver screenSaver;
    screenSaver.setScreenSaverEnabled(false);

    Box2DPlugin plugin;
    plugin.registerTypes("Box2DStatic");
    qmlRegisterType<LightedImageItem>("main", 1, 0, "LightedImage");
    qmlRegisterType<LightGroup>("main", 1, 0, "LightGroup");

    QUrl url{QStringLiteral("http://localhost:1234")};
    for (const QHostAddress &address : QNetworkInterface::allAddresses())
        if (address.protocol() == QAbstractSocket::IPv4Protocol && address != QHostAddress(QHostAddress::LocalHost)) {
            url.setHost(address.toString());
            break;
        }

    QQmlApplicationEngine engine;
    engine.addImageProvider("main", new ImageProvider{url});
    engine.load(QUrl{"qrc:/qml/main.qml"});
    engine.rootObjects().first()->setProperty("connectUrl", url);

    // Use a blocking queued connection to make sure that we've initialized the QML Connection before emitting any message from the server thread.
    GameServer server(1234);
    QObject::connect(&server, SIGNAL(playerConnected(const QVariant &)), engine.rootObjects().first(), SLOT(onPlayerConnected(const QVariant &)), Qt::BlockingQueuedConnection);
    QObject::connect(&server, SIGNAL(playerDisconnected(const QVariant &)), engine.rootObjects().first(), SLOT(onPlayerDisconnected(const QVariant &)));

    return a.exec();
}
