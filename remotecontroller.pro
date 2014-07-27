QT       += gui quick websockets

TARGET = chatserver
CONFIG   += c++11
CONFIG   -= app_bundle

TEMPLATE = app

SOURCES += \
    main.cpp \
    chatserver.cpp

HEADERS += \
    chatserver.h

OTHER_FILES += *.html
