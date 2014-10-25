QT       += gui quick websockets

CONFIG   += c++11
CONFIG   -= app_bundle

TEMPLATE = app

SOURCES += \
    main.cpp \
    gameserver.cpp \
    httpserver.cpp \
    lightedimageitem.cpp

HEADERS += \
    gameserver.h \
    httpserver.h \
    lightedimageitem.h

OTHER_FILES += *.html
