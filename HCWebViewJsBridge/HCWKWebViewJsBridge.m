//
//  HCWKJsBridge.m
//  Demo
//
//  Created by 刘海川 on 2019/9/20.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCWKWebViewJsBridge.h"

static NSString * const kWKHandleMessageFunction = @"handleMessage";
static NSString * const kWKHandleResponseMessageFunction = @"handleResponseMessage";
static NSString * const kWKHandleStartupMessageFunction = @"handleStartupMessage";
static NSString * const kWKMessageName = @"name";
static NSString * const kWKMessageData = @"data";
static NSString * const kWKMessageCallback = @"callbackId";
static NSString * const kWKMessageResponseId = @"responseId";
static NSString * const kWKMessageResponseData = @"responseData";
static NSString * const kWKResponseCallbackJsScript = @"hcJsBridge.handleMessageFromNative('%@');";

static NSString * const kJsBridgeApiSpacenameDefault = @"default";

@interface HCWKWebViewJsBridge () <WKScriptMessageHandler> {
    __weak WKWebView* _webView;
    
    NSMutableDictionary<NSString *, id> *_apiDictionary;
    NSMutableDictionary<NSString *, NSArray<HCJsApiMethod *> *> *_cacheApiMethodDictionary;
    NSMutableDictionary<NSString *, HCJBResponseCallback> *_responseCallbackDictionary;
    NSMutableArray<NSDictionary *> *_startupMessageQueue;
    BOOL _isDebug;
}

@end

@implementation HCWKWebViewJsBridge

#pragma mark - 构造器
+ (instancetype _Nonnull)bridgeWithWebView:(WKWebView * _Nonnull)webView {
    HCWKWebViewJsBridge *bridge = [[self alloc] init];
    [bridge hc_initSetup:webView];
    return bridge;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _responseCallbackDictionary = [[NSMutableDictionary alloc] init];
        _startupMessageQueue = [[NSMutableArray alloc] init];
        
        _apiDictionary = [[NSMutableDictionary alloc] init];
        _cacheApiMethodDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    WKUserContentController *userContentController = [[_webView configuration] userContentController];
    [userContentController removeScriptMessageHandlerForName:kWKHandleMessageFunction];
    [userContentController removeScriptMessageHandlerForName:kWKHandleResponseMessageFunction];
    [userContentController removeScriptMessageHandlerForName:kWKHandleStartupMessageFunction];
}

#pragma mark - Private Method
- (void)hc_initSetup:(WKWebView *)webView {
    _webView = webView;
    WKUserContentController *userContentController = [[_webView configuration] userContentController];
    [userContentController addScriptMessageHandler:self name:kWKHandleMessageFunction];
    [userContentController addScriptMessageHandler:self name:kWKHandleResponseMessageFunction];
    [userContentController addScriptMessageHandler:self name:kWKHandleStartupMessageFunction];
}

#pragma mark - Public Api
- (void)addJsBridgeApiObject:(id _Nonnull)apiObject {
    [self addJsBridgeApiObject:apiObject namespace:nil];
}

- (void)addJsBridgeApiObject:(id _Nonnull)apiObject namespace:(NSString * _Nullable)name {
    if ([HCWebViewJsBridgeUtil isNull:apiObject]) {
        HCJBLog(@"Method(AddJsBridgeApiObject) call failed, api object cannot be null");
        return;
    }
    NSString *namespace = name;
    if ([HCWebViewJsBridgeUtil isNull:namespace] || [@"" isEqualToString:namespace]) {
        namespace = kJsBridgeApiSpacenameDefault;
    }
    [_apiDictionary setObject:apiObject forKey:namespace];
    if (_isDebug) {
        HCJBDebugLog(@"Already added the api object(%@.m) to HCWKWebViewJsBridge, namespace is %@", NSStringFromClass([apiObject class]), namespace);
    }
}

- (void)callHandler:(NSString * _Nonnull)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString * _Nonnull)handlerName
               data:(id _Nullable )data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString * _Nonnull)handlerName
   responseCallback:(HCJBResponseCallback _Nullable)responseCallback {
    [self callHandler:handlerName data:nil responseCallback:responseCallback];
}

- (void)callHandler:(NSString * _Nonnull)handlerName
               data:(id _Nullable)data
   responseCallback:(HCJBResponseCallback _Nullable)responseCallback {
    if ([HCWebViewJsBridgeUtil isNull:handlerName]) {
        HCJBLog(@"Method(AcallHandler:data:responseCallback) call failed, handlerName cannot be null");
        return;
    }
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[kWKMessageName] = handlerName;
    if ([HCWebViewJsBridgeUtil nonNull:data]) {
        message[kWKMessageData] = data;
    }
    if ([HCWebViewJsBridgeUtil nonNull:responseCallback]) {
        NSString *callbackId = [HCWebViewJsBridgeUtil generateCallbackId];
        message[kWKMessageCallback] = callbackId;
        _responseCallbackDictionary[callbackId] = [responseCallback copy];
    }
    if (_startupMessageQueue) {
        [_startupMessageQueue addObject:message];
    } else {
        [self sendMessage:message];
    }
    if (_isDebug) {
        HCJBDebugLog(@"Native calling api of js(%@), data is %@, responseCallback is %@", handlerName, data, responseCallback);
    }
}

- (void)enableDebugLogging:(BOOL)debug {
    _isDebug = debug;
}

#pragma mark - delegate WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSString *scriptMessageName = message.name;
    if ([kWKHandleMessageFunction isEqualToString:scriptMessageName]) {
        NSString *messageJson = message.body;
        NSError *jsonError;
        NSData *msgData = [messageJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *message = [NSJSONSerialization JSONObjectWithData:msgData options:0 error:&jsonError];
        if (jsonError) {
            HCJBLog(@"Method(handleMessage) call failed, json(messageJson) parsing error:%@", [jsonError description]);
            return;
        }
        if ([HCWebViewJsBridgeUtil isNull:message]) {
            HCJBLog(@"Method(handleMessage) call failed, message body cannot be null");
            return;
        }
        if (![message isKindOfClass:[NSDictionary class]]) {
            HCJBLog(@"Method(handleMessage) call failed, message body should be NSDictionary");
            return;
        }
        NSString *messageName = message[kWKMessageName];
        if ([HCWebViewJsBridgeUtil isNull:messageName]) {
            HCJBLog(@"Method(handleMessage) call failed, message name cannot be null");
            return;
        }
        id messageData = message[kWKMessageData];
        if ([HCWebViewJsBridgeUtil isNull:messageData]) {
            messageData = nil;
        }
        if (_isDebug) {
            HCJBDebugLog(@"Js calling api of native(%@), data is %@", messageName, messageData);
        }
        NSString *responseId = message[kWKMessageCallback];
        HCJBResponseCallback responseCallback;
        if ([HCWebViewJsBridgeUtil nonNull:responseId]) {
            responseCallback = ^(id responseData) {
                if (responseData == nil) {
                    responseData = [NSNull null];
                }
                [self sendMessage:@{kWKMessageResponseData: responseData, kWKMessageResponseId: responseId}];
            };
        }
        
        HCJsApiName *apiName = [HCWebViewJsBridgeUtil resolveMessageName:messageName];
        if (apiName) {
            HCJsBridgeHandleApiResultType result = [HCWebViewJsBridgeUtil handleApiWithName:apiName
                                                                                       data:messageData
                                                                                   callback:responseCallback
                                                                                    apiDict:_apiDictionary
                                                                                  cacheDict:_cacheApiMethodDictionary];
            if (result == HCJsBridgeHandleApiResultTypeNotFoundTarget) {
                HCJBLog(@"Api Method call failed, because api object not found, please check the message name(%@).", messageName);
            } else if (result == HCJsBridgeHandleApiResultTypeNotFoundMethod) {
                HCJBLog(@"Api Method call failed, because method not found, please check the message name(%@).", messageName);
            } else if (result == HCJsBridgeHandleApiResultTypeSuccess){
                if (_isDebug) {
                    HCJBDebugLog(@"Js call api of native(%@) succeeded", messageName);
                }
            }
        } else {
            HCJBLog(@"Error parsing namespace, please check the message name(%@).", messageName);
        }
    } else if ([kWKHandleStartupMessageFunction isEqualToString:scriptMessageName]) {
        if (_startupMessageQueue) {
            [_startupMessageQueue enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self sendMessage:obj];
            }];
            if (_isDebug) {
                HCJBDebugLog(@"Already called all handler of startup");
            }
            _startupMessageQueue = nil;
        }
    } else if ([kWKHandleResponseMessageFunction isEqualToString:scriptMessageName]) {
        NSString *messageJson = message.body;
        NSError *jsonError;
        NSData *msgData = [messageJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *message = [NSJSONSerialization JSONObjectWithData:msgData options:0 error:&jsonError];
        if (jsonError) {
            HCJBLog(@"Method(handleResponseMessage) call failed, json(messageJson) parsing error:%@", [jsonError description]);
            return;
        }
        NSDictionary *scriptMessageBody = message;
        NSString *responseId = scriptMessageBody[kWKMessageResponseId];
        if ([HCWebViewJsBridgeUtil isNull:responseId]) {
            HCJBLog(@"Method(handleResponseMessage) call failed, responseId cannot be null, Note:Native may not require a callback");
            return;
        }
        id messageData = scriptMessageBody[kWKMessageResponseData];
        HCJBResponseCallback callback = _responseCallbackDictionary[responseId];
        if ([HCWebViewJsBridgeUtil isNull:messageData]) {
            messageData = nil;
        }
        callback(messageData);
    }
    
}

- (void)sendMessage:(NSDictionary *)message {
    NSError *error;
    NSString *messageJson = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:&error] encoding:NSUTF8StringEncoding];
    if (error) {
        HCJBLog(@"Method(sendMessage) call failed, an error occurred when the object(message) was converted to json:%@", [error description]);
        return;
    }
    NSString* javascriptCommand = [NSString stringWithFormat:kWKResponseCallbackJsScript, messageJson];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_webView evaluateJavaScript:javascriptCommand completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                HCJBLog(@"Method(sendMessage) call failed, evaluateJavaScript error:%@", [error description]);
            }
        }];
    });
}

@end
