QT *= core network

HEADERS += $$PWD/qscreensaver.h
SOURCES += $$PWD/qscreensaver.cpp
INCLUDEPATH += $$PWD

win32 {
    win32-msvc*: {
        LIBS += -lUser32
    }

    win32-g++*: {
        LIBS += -luser32
    }

    HEADERS += $$PWD/windows/qscreensaver_win_p.h
    SOURCES += $$PWD/windows/qscreensaver_win.cpp
}

linux-* {
    HEADERS += $$PWD/linux/qscreensaver_linux_p.h
    SOURCES += $$PWD/linux/qscreensaver_linux.cpp

    x11|config_x11: !contains(CONFIG,nox11option) {
        CONFIG += link_pkgconfig
        PKGCONFIG += x11
    } else: {
        DEFINES += QT_NO_X11
    }
}

macx {
    OBJECTIVE_SOURCES += $$PWD/mac/qscreensaver_mac.mm
    HEADERS += $$PWD/mac/qscreensaver_mac_p.h

    LIBS += -framework CoreServices
}
