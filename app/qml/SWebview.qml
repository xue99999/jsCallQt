import QtQuick 2.0
import QtQuick.Window 2.2
import com.syberos.basewidgets 2.0
import QtQml.Models 2.2
import QtWebEngine 1.5
import QtWebChannel 1.0

CPage {
    //加载信号
    signal onLoadProgress(var loadProgress)
    //返回键信号
    signal keyOnReleased(var event)
    property var surl

    //执行JavaScript代码
    function evaluateJavaScript(res){
        if(typeof res ==='string'){
            swebview.runJavaScript('success(' + res + ')', function(result){
             console.log('evaluateJavaScript:', res, 'result:', result);
            })
        }else{
            var param = JSON.stringify(res)
            swebview.runJavaScript('success(' + param + ')', function(result){
             console.log('evaluateJavaScript:', param, 'result:', result);
            })
        }

    }
    //是否能回退
    function canGoBack(){
        return swebview.canGoBack;
    }

    function canGoForward(){
        return swebview.canGoForward
    }
    //Go backward within the browser's session history, if possible. (Equivalent to the window.history.back() DOM method.)
    function goBack(){
        swebview.goBack();
    }
    //Go forward within the browser's session history, if possible. (Equivalent to the window.history.forward() DOM method.)
    function goForward(){
        swebview.goForward();
    }

    //return the swebview
    function getWebview(){
        return swebview
    }
    //Returns true if the HTML page is currently loading, false otherwise.
    function loading(){
        return swebview.loading;
    }
    //return swebview url
    function getCurrentUrl(){
        return swebview.url.toString();
    }
    //打开url
    function openUrl(url){
        console.log('swebview openUrl()',url)
        if(swebview.loading){
            console.log('swebview loading',swebview.loading)
            swebview.stop();
        }
        swebview.url=url;
    }
    //停止当前所有动作
    function stop(){
        swebview.stop();
    }
    //重新加载webview
    function reload(url){
        swebview.stop();
        swebview.reload();
    }

    function receiveMessage(message) {
        console.log('receiveMessage: ', typeof message, typeof message.data, message);
        var model = JSON.parse(message);


        console.log('**********model**********', JSON.stringify(model));

        var method = model.handlerName;
        var module = model.module;

        var funcArgs = {};
        if (model.data) {
          funcArgs = model.data;
        }

        // 因为C++类都为大写开头,所以第一个字母转为大写
        var moduleName = module.charAt(0).toUpperCase() + module.slice(1);

        console.log('**********moduleName**********',moduleName);
        console.log('**********method**********',method);
        console.log('**********method**********', JSON.stringify(funcArgs));
        NativeSdkManager.request(moduleName, 111, method, funcArgs);
    }

    Keys.onReleased: {
        console.log('SWebview qml Keys.onReleased',Keys.onReleased)
        keyOnReleased(event)
    }

    contentAreaItem:Rectangle{
        id:root
        anchors.fill:parent

        ObjectModel {
           id: trans
           WebChannel.id: "trans"

           function postMessage(msg){
               console.log('trans postMessage ', msg)
               receiveMessage(JSON.stringify(msg))
           }
       }

        WebChannel {
            id: channel
            registeredObjects: [trans]
        }

        WebEngineView {
            id: swebview
            focus: true
            zoomFactor: 3

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            url:surl
            webChannel: channel

            onContextMenuRequested: function (request) {
                 request.accepted = true;
            }
        }

    }
    Component.onCompleted: {
        //设置是否显示状态栏，应与statusBarHoldItemEnabled属性一致
        gScreenInfo.setStatusBar(true);
        //设置状态栏样式，取值为"black"，"white"，"transwhite"和"transblack"
        //gScreenInfo.setStatusBarStyle("transblack");
    }
}
