# WebViewJsBridge-iOS

WebViewJsBridge-iOS is a tool library for communication between HTML5 and UIWebView & WKWebView.

WebViewJsBridge-Android：[https://github.com/al-liu/WebViewJsBridge-Android](https://github.com/al-liu/WebViewJsBridge-Android)
[Chinese-Document 中文文档](./README-CH.md)

It is cross-platform supports iOS, Android, JavaScript and easy to use. It is non-intrusive to WebView. Support the use of classes to manage apis, each implementation class corresponds to a unique namespace, such as ui.alert, ui is a namespace, and alert is an implementation method.

Refer to the following diagram:

![WebViewJsBridge-namespace.png](https://i.loli.net/2019/10/08/a8hiDPQNAUOlByo.png)

## Requirements
iOS7 and above are supported if UIWebView is used.
iOS8 and above are supported if WKWebView is used.

## Installation

### CocoaPods
[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate WebViewJsBridge-iOS into your Xcode project using CocoaPods, specify it in your Podfile:

```oc
platform :ios, '8.0'

target 'TargetName' do
  pod 'HCWebViewJsBridge', '~> 1.0.0'
end
```

Then, run the following command:

```oc
$ pod install
```

### Manually
Download the source code for HCWebViewJsBridge and add it to your project to use it.

### Install HCWebViewJsBridge in HTML5
`<script>hcJsBridge.js</script>` in html.

## Example 的说明
The full example is provided in the `/Example/iOS Example` folder, including basic demos and advanced usage, such as calling the camera with `UIImagePickerController` to take a picture and using `NSURLSession` to make a GET request.

## Usage

### Initialize WebViewJsBridge in native

#### UIWebView

```oc
_bridge = [HCWebViewJsBridge bridgeWithWebView:self.webView];
```

#### WKWebView

```oc
_bridge = [HCWKWebViewJsBridge bridgeWithWebView:self.wkWebView];
```

### Register implementation class in native

```oc
UIJsApi *uiApi = [UIJsApi new];
[_bridge addJsBridgeApiObject:uiApi namespace:@"ui"];

RequestJsApi *requestJsApi = [RequestJsApi new];
[_bridge addJsBridgeApiObject:requestJsApi namespace:@"request"];
```

#### UIJsApi implementation class

```oc
- (void)alert:(NSDictionary *)data callback:(HCJBResponseCallback)callback {
    callback(@"native api alert’callback.");
}
// The implementation class supports four method signatures：
// 1. With parameters, with callbacks
- (void)test1:(NSString *)data callback:(HCJBResponseCallback)callback {
    NSLog(@"Js call native api test1, data is:%@", data);
    callback(@"native api test1’callback.");
}
// 2. With parameters, no callbacks
- (void)test2:(NSDictionary *)data {
    NSLog(@"Js native api:test2, data is:%@", data);
}
// 3. No parameters, no callbacks
- (void)test3 {
    NSLog(@"Js native api:test3");
}
// 4. No parameters, with callbacks
- (void)test4:(HCJBResponseCallback)callback {
    NSLog(@"Js native api:test4");
    callback(@"native api test4'callback.");
}
```

### Calls the HTML5 api in native

```oc
[_bridge callHandler:@"testCallJs" data:@{@"foo": @"bar"} responseCallback:^(id  _Nonnull responseData) {
    NSLog(@"testCallJs callback data is:%@", responseData);
}];
```

### Initialize WebViewJsBridge in HTML5

```js
<!DOCTYPE html>
<html>
    <head>
        ...
        <script src="./hcJsBridge.js"> </script>
    </head>
    ...
</html>
```

### Register apis for native call in HTML5

```js
hcJsBridge.registerHandler("testCallJs", function(data, callback) {
    log('Native call js ,handlename is testCallJs, data is:', data);
    callback('callback native, handlename is testCallJs');
})
```

### Calls native api in HTML5

```js
var data = {foo: "bar"};
hcJsBridge.callHandler('ui.alert', data, function (responseData) {
    log('Js receives the response data returned by native, response data is', responseData);
})
```

### Turn on the debug log

Turn on the debug log and print some call information to help troubleshoot the issue. The debug log is not enabled by default. The debug log is blocked in release mode, but the error log is not masked.

```oc
[_bridge enableDebugLogging:YES];
```

## License
WebViewJsBridge-iOS is released under the MIT license. See [LICENSE](./LICENSE)  for details.


