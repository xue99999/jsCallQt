import QtQuick 2.0
import QtQuick.Window 2.2
import com.syberos.basewidgets 2.0

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
