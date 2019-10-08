#include "demo.h"
#include "helper.h"

#include <QDebug>
#include <QUrlQuery>
#include <QQuickView>
#include <QMetaObject>
#include <QGuiApplication>
#include "util/fileutil.h"
#include "framework/common/errorinfo.h"

int Demo::typeId = qRegisterMetaType<Demo *>();

Demo::Demo(){
}

Demo::~Demo(){
}

void Demo::request(QString callBackID, QString actionName, QVariantMap params){
    qDebug() << Q_FUNC_INFO << "request" << callBackID << endl;

    if(actionName == "test"){
        test(callBackID.toLong(),params);
    }
}

void Demo::submit(QString typeID, QString callBackID, QString actionName, QVariant dataRowList, QVariant attachementes)
{
    Q_UNUSED(typeID)
    Q_UNUSED(callBackID)
    Q_UNUSED(actionName)
    Q_UNUSED(dataRowList)
    Q_UNUSED(attachementes)
}

void Demo::test(long callBackID,QVariantMap params){
    qDebug() << Q_FUNC_INFO << "test" << params << endl;

    // 取页面传过来的参数
    QString name = params.value("content").toString();

    if (name.isEmpty()) {
        emit failed(callBackID, 1001, "content参数不能为空");
    } else {
        QJsonObject jsonObject;
        jsonObject.insert("content", name);
        QJsonValue::fromVariant(jsonObject);
        emit success(callBackID, QVariant(jsonObject));
    }
}
