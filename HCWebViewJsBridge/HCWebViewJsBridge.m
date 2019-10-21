//
//  HCJsBridge.m
//  Demo
//
//  Created by 刘海川 on 2019/9/17.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCWebViewJsBridge.h"
#import "NSObject+HCJSContext.h"
#import "HCCoreJSExportImpl.h"
#import "HCJsApiMethod.h"
#import "HCJsApiName.h"
#import "HCWebViewJsBridgeUtil.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "HCWebViewJavaScript.h"

static NSString * const kCoreJSExport = @"nativeBridgeHead";
static NSString * const kCoreJsBridge = @"hcJsBridge";

static NSString * const kMessageName = @"name";
static NSString * const kMessageData = @"data";
static NSString * const kMessageCallbackId = @"callbackId";
static NSString * const kMessageResponseId = @"responseId";
static NSString * const kMessageResponseData = @"responseData";

static NSString * const kCoreJsBridgeMessageHandler = @"handleMessageFromNative";

static NSString * const kJsBridgeApiSpacenameDefault = @"default";

@interface HCWebViewJsBridge () <HCCoreJSExportDelegate> {
    __weak UIWebView *_webView;
    JSContext *_jsContext;
    NSThread *_webThread;
    NSMutableDictionary<NSString *, id> *_apiObjectDictionary;
    NSMutableDictionary<NSString *, NSArray<HCJsApiMethod *> *> *_cacheApiMethodDictionary;
    NSMutableArray<NSDictionary *> *_startupMessageQueue;
    NSMutableDictionary<NSString *, HCJBResponseCallback> *_responseCallbackDictionary;
    BOOL _isDebug;
    BOOL _enableAutoInjectJs;
}

@end

@implementation HCWebViewJsBridge

#pragma mark - Constructor
+ (instancetype _Nonnull)bridgeWithWebView:(UIWebView * _Nonnull)webView {
    return [HCWebViewJsBridge bridgeWithWebView:webView injectJS:NO];
}

+ (instancetype _Nonnull)bridgeWithWebView:(UIWebView * _Nonnull)webView injectJS:(BOOL)enable {
    HCWebViewJsBridge *bridge = [[self alloc] init];
    [bridge hc_initSetup:webView injectJs:enable];
    return bridge;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self hc_registerCreateJSContextNotification];
        _apiObjectDictionary = [[NSMutableDictionary alloc] init];
        _cacheApiMethodDictionary = [[NSMutableDictionary alloc] init];
        _responseCallbackDictionary = [[NSMutableDictionary alloc] init];
        _startupMessageQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self hc_unregisterCreateJSContextNotification];
}

#pragma mark - Public Method Impl
- (void)addJsBridgeApiObject:(id _Nonnull)apiObject {
    [self addJsBridgeApiObject:apiObject namespace:nil];
}

- (void)addJsBridgeApiObject:(id _Nonnull)apiObject
                   namespace:(NSString * _Nullable)name {
    if ([HCWebViewJsBridgeUtil isNull:apiObject]) {
        HCJBLog(@"Method(AddJsBridgeApiObject) call failed, api object cannot be null");
        return;
    }
    NSString *namespace = name;
    if ([HCWebViewJsBridgeUtil isNull:namespace] || [@"" isEqualToString:namespace]) {
        namespace = kJsBridgeApiSpacenameDefault;
    }
    [_apiObjectDictionary setObject:apiObject forKey:namespace];
    
    if (_isDebug) {
        HCJBDebugLog(@"Already added the api object(%@.m) to HCWebViewJsBridge, namespace is %@", NSStringFromClass([apiObject class]), namespace);
    }
}

- (void)callHandler:(NSString*)handlerName {
    [self callHandler:handlerName data:nil];
}

- (void)callHandler:(NSString*)handlerName
               data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString * _Nonnull)handlerName
   responseCallback:(HCJBResponseCallback _Nullable)responseCallback {
    [self callHandler:handlerName data:nil responseCallback:responseCallback];
}

- (void)callHandler:(NSString*)handlerName
               data:(id)data
   responseCallback:(HCJBResponseCallback)responseCallback {
    if ([HCWebViewJsBridgeUtil isNull:handlerName]) {
        HCJBLog(@"Method(AcallHandler:data:responseCallback) call failed, handlerName cannot be null");
        return;
    }
    NSMutableDictionary *message = [@{kMessageName:handlerName,
                                      kMessageData:
                                          [HCWebViewJsBridgeUtil isNull:data] ? [NSNull null] : data} mutableCopy];
    if ([HCWebViewJsBridgeUtil nonNull:responseCallback]) {
        NSString *callbackId = [HCWebViewJsBridgeUtil generateCallbackId];
        message[kMessageCallbackId] = callbackId;
        _responseCallbackDictionary[callbackId] = [responseCallback copy];
    }
    if (_startupMessageQueue) {
        [_startupMessageQueue addObject:message];
    } else {
        [self hc_sendMessage:message];
    }
    if (_isDebug) {
        HCJBDebugLog(@"Native calling api of js(%@), data is %@, responseCallback is %@", handlerName, data, responseCallback);
    }
}

- (void)enableDebugLogging:(BOOL)debug {
    _isDebug = debug;
}

#pragma mark - Private Method
- (void)hc_initSetup:(UIWebView *)webView injectJs:(BOOL)enable {
    _webView = webView;
    _enableAutoInjectJs = enable;
}

- (void)hc_sendMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        JSValue *jsBridge = [self->_jsContext objectForKeyedSubscript:kCoreJsBridge];
        if ([HCWebViewJsBridgeUtil isNull:jsBridge]) {
            HCJBLog(@"Method(hc_sendMessage) call failed, the global object's property(hcJsBridge) of js does not exist");
            return;
        }
        JSValue *handleMessage = [jsBridge objectForKeyedSubscript:kCoreJsBridgeMessageHandler];
        if ([HCWebViewJsBridgeUtil isNull:handleMessage]) {
            HCJBLog(@"Method(hc_sendMessage) call failed, the global object(hcJsBridge)'s property(handleMessageFromNative) of js does not exist");
            return;
        }
        [handleMessage performSelector:@selector(callWithArguments:)
                              onThread:[HCWebViewJsBridgeUtil isNull:self->_webThread] ? [NSThread currentThread] : self->_webThread
                            withObject:@[message]
                         waitUntilDone:NO];
    });
}

- (void)hc_registerCreateJSContextNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCreateJSContext:)
                                                 name:kHCDidCreateJSContextNotification
                                               object:nil];
}

- (void)hc_unregisterCreateJSContextNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kHCDidCreateJSContextNotification
                                                  object:nil];
}

- (void)hc_injectCoreJSExportImpl {
    HCCoreJSExportImpl *coreJsExport = [HCCoreJSExportImpl new];
    coreJsExport.delegate = self;
    _jsContext[kCoreJSExport] = coreJsExport;
}

#pragma mark - Notification Selector
- (void)didCreateJSContext:(NSNotification *)notification {
    NSString *identifier = [NSString stringWithFormat:@"jsContext_indentifier_%lud", (long)_webView.hash];
    NSString *identifierJS = [NSString stringWithFormat:@"var %@ = '%@'", identifier, identifier];
    [_webView stringByEvaluatingJavaScriptFromString:identifierJS];
    JSContext *context = notification.object;
    if (![context[identifier].toString isEqualToString:identifier]) return;
    _jsContext = context;
    [self hc_injectCoreJSExportImpl];
    if (_enableAutoInjectJs) {
        [_jsContext evaluateScript:hcJsBridgeJavaScript()];
    }
    _jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        HCJBLog(@"JsContext_exceptionHandler: %@", exception);
        context.exception = exception;
    };
}

#pragma mark - HCCoreJSExportDelegate
- (void)handleMessage:(NSString *)messageJson webThread:(nonnull NSThread *)webThread {
    _webThread = webThread;
    NSError *jsonError;
    NSData *msgData = [messageJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:msgData options:0 error:&jsonError];
    if (jsonError) {
        HCJBLog(@"Method(handleMessage) call failed, json(messageJson) parsing error:%@", [jsonError description]);
        return;
    }
    NSString *name = message[kMessageName];
    NSDictionary *data = message[kMessageData];
    NSString *callbackId = message[kMessageCallbackId];
    if ([HCWebViewJsBridgeUtil isNull:name]) {
        HCJBLog(@"Method(handleMessage) call failed, message name cannot be null");
        return;
    }
    if (_isDebug) {
        HCJBDebugLog(@"Js calling api of native(%@), data is %@", name, data);
    }
    if ([HCWebViewJsBridgeUtil isNull:data]) {
        data = nil;
    }
    HCJBResponseCallback responseCallback;
    if ([HCWebViewJsBridgeUtil nonNull:callbackId]) {
        responseCallback = ^(id responseData) {
            if (responseData == nil) {
                responseData = [NSNull null];
            }
            NSDictionary *responseMessage = @{kMessageResponseId: callbackId, kMessageResponseData: responseData};
            [self hc_sendMessage:responseMessage];
        };
    }
    HCJsApiName *apiName = [HCWebViewJsBridgeUtil resolveMessageName:name];
    if (apiName) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HCJsBridgeHandleApiResultType result = [HCWebViewJsBridgeUtil handleApiWithName:apiName
                                                                                       data:data
                                                                                   callback:responseCallback
                                                                                    apiDict:self->_apiObjectDictionary
                                                                                  cacheDict:self->_cacheApiMethodDictionary];
            if (result == HCJsBridgeHandleApiResultTypeNotFoundTarget) {
                HCJBLog(@"Api Method call failed, because api object not found, please check the message name(%@).", name);
            } else if (result == HCJsBridgeHandleApiResultTypeNotFoundMethod) {
                HCJBLog(@"Api Method call failed, because method not found, please check the message name(%@).", name);
            } else if (result == HCJsBridgeHandleApiResultTypeErrorArgument) {
                HCJBLog(@"Api Method call failed, because pass error argument, please check the data or callback.");
            } else if (result == HCJsBridgeHandleApiResultTypeSuccess){
                if (self->_isDebug) {
                    HCJBDebugLog(@"Js call api of native(%@) succeeded", name);
                }
            }
        });
    } else {
        HCJBLog(@"Error parsing namespace, please check the message name(%@).", name);
    }
}

- (void)handleResponseMessage:(NSString *)messageJson webThread:(nonnull NSThread *)webThread{
    _webThread = webThread;
    NSError *jsonError;
    NSData *msgData = [messageJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:msgData options:0 error:&jsonError];
    if (jsonError) {
        HCJBLog(@"Method(handleResponseMessage) call failed, json(messageJson) parsing error:%@", [jsonError description]);
        return;
    }
    NSString *responseId = message[kMessageResponseId];
    if ([HCWebViewJsBridgeUtil isNull:responseId]) {
        HCJBLog(@"Method(handleResponseMessage) call failed, responseId cannot be null, Note:Native may not require a callback");
        return;
    }
    id responseData = message[kMessageResponseData];
    if (_responseCallbackDictionary) {
        HCJBResponseCallback callback = _responseCallbackDictionary[responseId];
        if (callback) {
            callback(responseData);
        }
    }
}

- (void)handleStartupMessageWithWebThread:(NSThread *)webThread{
    _webThread = webThread;
    if (_startupMessageQueue) {
        [_startupMessageQueue enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *message = obj;
            [self hc_sendMessage:message];
        }];
        if (_isDebug) {
            HCJBDebugLog(@"Already called all handler of startup");
        }
        _startupMessageQueue = nil;
    }
}

@end
