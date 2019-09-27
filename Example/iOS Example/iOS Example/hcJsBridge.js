;(function() {

    if (window.hcJsBridge) {
        return;
    }

    window.hcJsBridge = {
        callHandler: callHandler,
        registerHandler: registerHandler,
        handleMessageFromNative: handleMessageFromNative,
        messageHandlers: {},
        messageCallbacks: {}
    };
    var uniqueId = 1;

    function callHandler(name, data, responseCallback) {
        if (arguments.length == 2 && typeof data == 'function') {
            responseCallback = data;
            data = null;
        }
        var message = {name:name, data:data};
        if (responseCallback) {
            var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
            message["callbackId"] = callbackId;
            hcJsBridge.messageCallbacks[callbackId] = responseCallback;
        }
        var messageJson = JSON.stringify(message);
        if (typeof nativeBridgeHead === "undefined") {
            window.webkit.messageHandlers.handleMessage.postMessage(messageJson);
        } else {
            nativeBridgeHead.handleMessage(messageJson);
        }
    }

    function registerHandler(name, handler) {
        hcJsBridge.messageHandlers[name] = handler;
    }

    function handleMessageFromNative(messageJSON) {
        var message = messageJSON;
        if (typeof message != "object") {
            message = JSON.parse(messageJSON);
        }
        var responseId = message["responseId"];
        if (responseId) {
            var responseData = message["responseData"];
            var callback = hcJsBridge.messageCallbacks[responseId];
            callback(responseData);
        } else {
            var messageName = message["name"];
            var messageData = message["data"];
            var messageCallbackId = message["callbackId"];

            var handler = hcJsBridge.messageHandlers[messageName];
            var responseCallback = function(data) {
                var responseMessage = {
                    responseId: messageCallbackId,
                    responseData: data
                };
                var responseMessageJson = JSON.stringify(responseMessage);
                if (typeof nativeBridgeHead === "undefined") {
                    window.webkit.messageHandlers.handleResponseMessage.postMessage(responseMessageJson);
                } else {
                    nativeBridgeHead.handleResponseMessage(responseMessageJson);
                }
            };
            handler(messageData, responseCallback);
        }
    }

    setTimeout(function () {
        if (typeof nativeBridgeHead === "undefined") {
            window.webkit.messageHandlers.handleStartupMessage.postMessage("");
        } else {
            nativeBridgeHead.handleStartupMessage();
        }
    }, 0);
})();
