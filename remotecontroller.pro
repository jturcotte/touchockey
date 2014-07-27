QT       += gui quick websockets

CONFIG   += c++11
CONFIG   -= app_bundle

TEMPLATE = app

SOURCES += \
    main.cpp \
    gameserver.cpp

HEADERS += \
    gameserver.h

OTHER_FILES += *.html
