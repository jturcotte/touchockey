QT       += gui quick websockets
CONFIG   += c++11

TEMPLATE = app

!exists(qml-box2d/box2d-static.pri) {
    error("Can't find Box2D sources, please run `git submodule update --init`.")
}
include(qml-box2d/box2d-static.pri)
include(qtqrencode/qqrencode/qqrencode.pri)
include(qtsystems/src/systeminfo/qscreensaver.pri)
DEFINES += LIBQTQRENCODE_STATIC

SOURCES += \
    main.cpp \
    gameserver.cpp \
    httpserver.cpp \
    lightedimageitem.cpp \
    playerbox2dbody.cpp

HEADERS += \
    gameserver.h \
    httpserver.h \
    lightedimageitem.h \
    playerbox2dbody.h \
    shadowstrip.h

RESOURCES += touchockey.qrc resources.qrc
