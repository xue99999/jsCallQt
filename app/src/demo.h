#ifndef AUDIO_H
#define AUDIO_H

#include <QObject>
#include <QtMultimedia>
#include <QMediaPlayer>
#include <QMediaContent>

#include "framework/nativesdkhandlerbase.h"

class Demo : public NativeSdkHandlerBase
{
    Q_OBJECT
public:
    Q_INVOKABLE Demo();
    ~Demo();

    void request(QString callBackID,QString actionName,QVariantMap params);
    void submit(QString typeID,QString callBackID,QString actionName,QVariant dataRowList, QVariant attachementes);

    void test(long callBackID,QVariantMap params);


private :
    static int typeId;

};

#endif
