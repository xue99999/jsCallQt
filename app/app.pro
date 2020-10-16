include(../syberos.pri)

QT += gui qml quick widgets network multimedia core sql dbus

QT_VERSION = $$[QT_VERSION]
QT_VERSION = $$split(QT_VERSION, ".")
QT_VER_MAJ = $$member(QT_VERSION, 0)
QT_VER_MIN = $$member(QT_VERSION, 1)

lessThan(QT_VER_MAJ, 5) | lessThan(QT_VER_MIN, 6) {
  message(Qt版本小于5.6)
  QT += webkit
} else {
  message(Qt版本大于等于5.6)
  QT += webengine webchannel
}


TEMPLATE = app

TARGET = app

CONFIG += link_pkgconfig
CONFIG += C++11

RESOURCES += res.qrc

PKGCONFIG += syberos-application syberos-application-cache syberos-qt-system syberos-qt

QML_FILES = qml/*.qml

OTHER_FILES += $$QML_FILES *.qm

QMAKE_LFLAGS += -Wl,-rpath,$$INSTALL_DIR/lib
# The .cpp file which was generated for your project.
SOURCES += src/main.cpp \
    src/App_Workspace.cpp \
    src/helper.cpp \
    src/demo.cpp \
    src/util/uploadmanager.cpp \
    src/util/log.cpp \
    src/util/fileutil.cpp \
    src/util/downloadmanager.cpp \
    src/framework/nativesdkmanager.cpp \
    src/framework/nativesdkhandlerbase.cpp \
    src/framework/nativesdkfactory.cpp \
    src/framework/common/networkstatus.cpp \
    src/framework/common/extendedconfig.cpp \
    src/framework/common/errorinfo.cpp


HEADERS += \
    src/App_Workspace.h \
    src/helper.h \
    src/demo.h \
    src/util/uploadmanager.h \
    src/util/log.h \
    src/util/fileutil.h \
    src/util/downloadmanager.h \
    src/util/chalk.h \
    src/framework/nativesdkmanager.h \
    src/framework/nativesdkhandlerbase.h \
    src/framework/nativesdkfactory.h \
    src/framework/common/networkstatus.h \
    src/framework/common/extendedconfig.h \
    src/framework/common/errorinfo.h

# Installation path
target.path = $$INSTALL_DIR/bin

qm.files = *.qm
qm.path = $$INSTALL_DIR/qm

res.files = res/*.png
res.path = $$INSTALL_DIR/res

web.files = www
web.path = $$INSTALL_DIR

INSTALLS += target qm web res

DISTFILES += \
    res/app.png

DEFINES += EX_CONFIG=\\\"$$EX_CONFIG\\\"


