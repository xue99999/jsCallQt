# Syberos 中 JS和C++ 通讯示例

## JavaScript 通知 Native

基于QT WebView 的机制和开放的 API, 实现这个功能方案：
navigator.qt.postMessage ，通过QT WebView提供的方法发送信息到Native WebView。

**代码示例见app/www/lib/jsbridge.js**

JS端调用示例
``` javascript
    function requestOne() {
      var options={
        // 模块名
        proto: 'Demo*',
        // 方法名
        handlerName: 'test',
        // 参数
        data: {
          content: 'syberos first request'
        },
        // 成功回调
        success:function(res){
          console.log('request success', JSON.stringify(res))
        },
        // 失败回调
        fail:function(error){
          console.log('request fail', JSON.stringify(error))
        }
      }
    
      // 给QML发送消息
      JSBridge.callJsBridge(options);
    }
```


## QML如何实现

1、experimental.onMessageReceived :Native WebView 通过该方法接受JS端的通知。

2、发送请求到C++  
  
        C++给QML注入`NativeSdkManager`属性，通过`NativeSdkManager.request()`实现
3、接受C++成功或者失败信号后，返回给JavaScript端. 
   
       通过webview的evaluateJavaScript方法执行`JSBridge._handleMessageFromNative()`方法

**代码示例见app/qml/SPage.qml**

```
SWebview{
    id:spage
    surl:"file://" + helper.getWebRootPath() + "/index.html"
    Connections {
        target: spage
        //接受webView发出信号
        onReceiveMessage:{
            var data = message.data ? JSON.parse(message.data) : {}
            //调用C++
            NativeSdkManager.request(data.module, data.callbackId, data.handlerName, data.data)
        }
    }

    Component.onCompleted: {
        // 成功回调绑定函数
        NativeSdkManager.success.connect(function(callbackId, result){
            var resObj = {
              responseId: Number(callbackId),
              responseData: {
                result: result
              }
            }
            var res = JSON.stringify(resObj)

            //直接执行JS代码，调用JS实现的API。
            //此方法可以用来实现Native直接调用JS实现的方法。
            //为了兼容h5模式和实现原生直接调用js方法，采用此模式实现
            spage.evaluateJavaScript(res)

        })
        // 错误回调绑定函数
        NativeSdkManager.failed.connect(function(handlerId, errorCode, errorMsg){
            var obj = {
              responseId: Number(handlerId),
              responseData: {
                code: Number(errorCode),
                msg: errorMsg
              }
            }
            var res = JSON.stringify(obj)

            //直接执行JS代码，调用JS实现的API。
            //此方法可以用来实现Native直接调用JS实现的方法。
            //为了兼容h5模式和实现原生直接调用js方法，采用此模式实现
            spage.evaluateJavaScript(res)
        })
    }
}
```


## C++插件实现机制


1、提供`NativeSdkHandlerBase`基础类,该类提供了request、success、failed、subscribe信号的实现。

2、实现类需继承`NativeSdkHandlerBase` 类

**代码示例见demo.cpp**


``` c++
    void success(long responseID, QVariant result);
    void failed(long responseID,long errorCode,QString errorMsg);
    //订阅机制
    void subscribe(QString handleName,QVariant result);
```

`request`: 消息的统一实现类,拓展组件需要继承基础类该后实现request的处理,如:

``` c++
void Demo::request(QString callBackID, QString actionName, QVariantMap params){
    qDebug() << Q_FUNC_INFO << "request" << callBackID << endl;

    if(actionName == "test"){
        test(callBackID.toLong(),params);
    }
}
```

success:成功信号。拓展组件处理完成发送成功信号,处理正确结果。

``` c++
    emit success(callBackID, QVariant(json));
```
`failed`:失败信号,处理失败后，发送失败信号。

`subscribe`:订阅信号。实现原生直接通知前端的信号槽。如屏幕变动后主动告知前端。



