import QtQuick 2.0
import QtWebKit 3.0
import QtQuick.Window 2.2
import QtWebKit.experimental 1.0
import com.syberos.basewidgets 2.0

CPage{
    //加载信号
    signal onLoadProgress(var loadProgress)
    //返回键信号
    signal keyOnReleased(var event)
    //接受消息信号
    signal receiveMessage(var message)
    property var surl
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
    //示例一：执行JavaScript代码
    function evaluateJavaScript(result){
        swebview.experimental.evaluateJavaScript(
          'JSBridge._handleMessageFromNative('+ result +')'
        )
    }
    //示例二：发送一个消息
    function postMessage(result){
        swebview.experimental.postMessage(result)
    }
    Keys.onReleased: {
        console.log('SWebview qml Keys.onReleased',Keys.onReleased)
        keyOnReleased(event)
        //event.accepted = true
    }

    contentAreaItem:Rectangle{
        id:root
        anchors.fill:parent

        WebView {
            id: swebview
            focus: true
            signal downLoadConfirmRequest
            property url curHoverUrl: ""
            anchors.fill:parent
            url:surl
            experimental.userAgent: "Mozilla/5.0 (Linux; Android 4.4.2; GT-I9505 Build/JDQ39) SyberOS "+helper.aboutPhone().osVersionCode+";"
            experimental.minimumScale: false
            experimental.preferredMinimumContentsWidth: Screen.width
            experimental.deviceWidth:Screen.width
            experimental.deviceHeight:Screen.height
            experimental.objectName: 'qml'
            experimental.preferences.navigatorQtObjectEnabled: true

            experimental.onMessageReceived: {
                //发送qml信号
                receiveMessage(message)
            }


            experimental.preferences.minimumFontSize: 13
            experimental.gpsEnable: false

            property bool _autoLoad: true
            experimental.preferences.autoLoadImages: true //webviewManager.wifiStatus?true:((typeof setupMgr != undefined)?(setupMgr.getValue("autoloadimage",true)=="true"?true:false):false)

            onLinkHovered: {
                curHoverUrl= hoveredUrl
            }
            property string navigateUrl: ""
            property string telNumber: ""
            onNavigationRequested: {
                console.log("onNavigationRequested request.navigationType:",request.navigationType)
                console.log("onNavigationRequested",helper.getWebRootPath())
            }


            onUrlChanged: {
                console.log('SWebview onUrlChanged',loadProgress)
            }

            onLoadProgressChanged: {
                console.log('SWebview qml onLoadProgressChanged',loadProgress)
                onLoadProgress(loadProgress)
            }

            onSms: {
                console.log("onSms", url, body);
                gApp.openUrl("sms:?body=" + body);
            }

            onMailto: {
                console.log("onMailto url:[%s], body:[%s]", url, body);
                gApp.openUrl("email:writeMail?address="+ url + "&content=" + body + "&attach=");
            }

            Component.onCompleted: {
                console.log("SWebview Component.onCompleted")
                swebview.SetJavaScriptCanOpenWindowsAutomatically(false)
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
