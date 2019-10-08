# js调用c++

## js如何调用
通过JSBridge实现和QML通信，以及处理回调函数

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
和js通信:
    接收js发送的消息:
        接收webview的receiveMessage信号
    调用js代码:
        通过webview的evaluateJavaScript方法执行`JSBridge._handleMessageFromNative()`方法

和C++通信:
    调用C++代码:
        C++给QML注入`NativeSdkManager`属性，通过`NativeSdkManager.request()`实现
    接收C++发送的信号:
        绑定信号的方式实现， 例如：`NativeSdkManager.success.connect()`

代码示例见Spage.qml页面实现



## C++插件实现机制
提供`NativeSdkHandlerBase`基础类,该类提供了request、success、failed、subscribe信号的实现。

``` javascript
    void success(long responseID, QVariant result);
    void failed(long responseID,long errorCode,QString errorMsg);
    //订阅机制
    void subscribe(QString handleName,QVariant result);
```

`request`: 消息的统一实现类,拓展组件需要继承基础类该后实现request的处理,如:

``` javascript
void Demo::request(QString callBackID, QString actionName, QVariantMap params){
    qDebug() << Q_FUNC_INFO << "request" << callBackID << endl;

    if(actionName == "test"){
        test(callBackID.toLong(),params);
    }
}
```

success:成功信号。拓展组件处理完成发送成功信号,处理正确结果。

``` javascript
    emit success(callBackID, QVariant(json));
```
`failed`:失败信号,处理失败后，发送失败信号。

`subscribe`:订阅信号。实现原生直接通知前端的信号槽。如屏幕变动后主动告知前端。

代码示例见demo.cpp

