var JSBridge = {};

window.JSBridge = JSBridge;

// 本地注册的方法集合,原生只能调用本地注册的方法,否则会提示错误
const messageHandlers = {};
// 在原生调用完对应的方法后,会执行对应的回调函数id，并删除
var responseCallbacks = {};
// 长期存在的回调，调用后不会删除
var responseCallbacksLongTerm = {};


// 唯一id,用来确保长期回调的唯一性，初始化为最大值
var uniqueLongCallbackId = 2147483647;

/**
* 获取短期回调id，内部要避免和长期回调的冲突
* @return {Number} 返回一个随机的短期回调id
*/
function getCallbackId () {
  // 确保每次都不会和长期id相同
  return Math.floor(Math.random() * uniqueLongCallbackId);
}

/**
* 将JSON参数转为字符串
* @param {Object} data 对应的json对象
* @return {String} 转为字符串后的结果
*/
function getParam (data) {
  if (typeof data !== 'string') {
    return JSON.stringify(data);
  }

  return data;
}

/**
* 转换message对象为字符串
* @param proto module
* @param message
* @param {boolean}  isLong 是否为长回调
* @return {String} message 字符串
*
*/
var getMessageStr = function (proto, message, isLong) {
  if (typeof message !== 'string') {
    message.module = proto;
    message.isLong = isLong;
    return JSON.stringify(message);
  }
  return message;
};

/**
* JS调用原生方法前,会先send到这里进行处理
* @param {String} proto 这个属于协议头的一部分
* @param {JSON} message 调用的方法详情,包括方法名,参数
* @param {Object} responseCallback 调用完方法后的回调,或者长期回调的id
* @param {boolean} isLong 是否为长回调
*/
function doSend (proto, message, responseCallback, isLong) {

  isLong = isLong ? isLong : false
  var newMessage = message;
  if (typeof responseCallback === 'function') {
    // 如果传入的回调时函数，需要给它生成id
    // 取到一个唯一的callbackid
    var callbackId = getCallbackId();
    // 回调函数添加到短期集合中
    responseCallbacks[callbackId] = responseCallback;
    // 方法的详情添加回调函数的关键标识
    newMessage.callbackId = callbackId;
  } else {
    // 如果传入时已经是id，代表已经在回调池中了，直接使用即可
    newMessage.callbackId = responseCallback;
  }
  
  var messageStr = getMessageStr(proto, newMessage, isLong);
  navigator.qt.postMessage(messageStr);
}

/**
* 注册长期回调到本地
* @param {String} callbackId 回调id
* @param {Function} callback 对应回调函数
*/
JSBridge.registerLongCallback = function registerLongCallback (callbackId, callback) {
  responseCallbacksLongTerm[callbackId] = callback;
};

/**
* 获得本地的长期回调，每一次都是一个唯一的值
* @retrurn 返回对应的回调id
* @return {Number} 返回长期回调id
*/
JSBridge.getLongCallbackId = function getLongCallbackId () {
  return getCallbackId();
};

/**
* 调用原生开放的方法
* @param {String} proto 这个属于协议头的一部分
* @param {String} handlerName 方法名
* @param {JSON} data 参数
* @param {Object} callback 回调函数或者是长期的回调id
*/
JSBridge.callHandler = function callHandler (proto, handlerName, data, callback, isLong) {
  isLong = isLong ? isLong : false
  doSend(
    proto,
    {
      handlerName: handlerName,
      data: data
    },
    callback,
    isLong
  )
};

/**
* 原生调用H5页面注册的方法,或者调用回调方法
* @param {String} messageJSON 对应的方法的详情,需要手动转为json
*/
JSBridge._handleMessageFromNative = function _handleMessageFromNative (messageJSON) {
  if (!messageJSON) {
    return;
  }
  //处理原生过来的方法
  function doDispatchMessageFromNative () {
    var message;

    try {
      if (typeof messageJSON === 'string') {
        message = decodeURIComponent(messageJSON);
        message = JSON.parse(message);
      } else {
        message = messageJSON;
      }
    } catch (e) {
      console.error(globalError.ERROR_TYPE_NATIVECALL.code)
      console.error(globalError.ERROR_TYPE_NATIVECALL.msg)

      return;
    }

    // 回调函数
    var responseId = message.responseId;
    var responseData = message.responseData;
    var responseCallback;

    if (responseId) {
      // 这里规定,原生执行方法完毕后准备通知h5执行回调时,回调函数id是responseId
      responseCallback = responseCallbacks[responseId];
      // 默认先短期再长期
      responseCallback = responseCallback || responseCallbacksLongTerm[responseId];

      // 执行本地的回调函数
      responseCallback && responseCallback(responseData);

      delete responseCallbacks[responseId];
    } else {
      /**
        * 否则,代表原生主动执行h5本地的函数
        * 从本地注册的函数中获取
        */
      var handler = messageHandlers[message.handlerName];
      var data = message.data;

      // 执行本地函数,按照要求传入数据和回调
      handler && handler(data);
    }
  }

  // 使用异步
  setTimeout(doDispatchMessageFromNative);
};

// 和QML通信
JSBridge.callJsBridge = function callJsBridge(options, resolve, reject) {
    var success = options.success;
    var fail = options.fail;
    var dataFilter = options.dataFilter;
    var proto = options.proto;
    var handlerName = options.handlerName;
    var isLongCb = options.isLongCb;
    var isEvent = options.isEvent;
    var data = options.data;

    // 统一的回调处理
    var cbFunc = function (res) {
        if (res.code) {
            fail && fail(res);
            // 长期回调不走promise
            !isLongCb && reject && reject(res);
        } else {
            var finalRes = res;

            if (dataFilter) {
                finalRes = dataFilter(finalRes);
            }
            // 提取出result
            success && success(finalRes.result);
            !isLongCb && resolve && resolve(finalRes.result);
        }
    };

    if (isLongCb) {
        var longCbId = JSBridge.getLongCallbackId();
        if (isEvent) {
            // 如果是event，data里需要增加一个参数
            data.port = longCbId;
        }
        JSBridge.registerLongCallback(longCbId, cbFunc);
        // 传入的是id ,默认为long
        JSBridge.callHandler(proto, handlerName, data, longCbId, true);
        // 长期回调默认就成功了，这是兼容的情况，防止有人误用
        resolve && resolve();
    } else {
        // 短期回调直接使用方法
        JSBridge.callHandler(proto, handlerName, data, cbFunc);
    }
};