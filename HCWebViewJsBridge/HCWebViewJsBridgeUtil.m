//
//  HCWebViewJsBridgeUtil.m
//  Demo
//
//  Created by 刘海川 on 2019/9/21.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCWebViewJsBridgeUtil.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kJsBridgeApiSpacenameDefault = @"default";
static NSString * const kJsBridgeApiSpacenameSeparateSymbol = @".";
static NSString * const kJsBridgeApiSelArgCountSeparateSymbol = @":";

static NSString * const kJsBridgeNativeCallbackFormat = @"native_callback_%@";

@implementation HCWebViewJsBridgeUtil

#pragma mark - null judge
+ (BOOL)nonNull:(id)value {
    return value != nil
    && ![value isEqual:[NSNull null]]
    && ![@"undefined" isEqualToString:value];
}

+ (BOOL)isNull:(id)value {
    return value == nil
    || [value isEqual:[NSNull null]]
    || [@"undefined" isEqualToString:value];
}

+ (HCJsApiName *)resolveMessageName:(NSString *)name {
    NSArray *spacenameComponents = [name componentsSeparatedByString:kJsBridgeApiSpacenameSeparateSymbol];
    NSString *spacename, *messageName;
    if (spacenameComponents.count == 1) {
        spacename = kJsBridgeApiSpacenameDefault;
        messageName = name;
    } else if (spacenameComponents.count == 2) {
        spacename = spacenameComponents[0];
        messageName = spacenameComponents[1];
    } else {
        return nil;
    }
    return [[HCJsApiName alloc] initWithName:messageName spacename:spacename];
}

+ (HCJsBridgeHandleApiResultType)handleApiWithName:(HCJsApiName *)apiName
                                              data:(id)data
                                          callback:(HCJBResponseCallback)responseCallback
                                           apiDict:(NSDictionary *)apiDict
                                         cacheDict:(NSMutableDictionary *)cacheDict {
    id target = apiDict[apiName.spacename];
    if (!target) {
        return HCJsBridgeHandleApiResultTypeNotFoundTarget;
    }
    NSArray<HCJsApiMethod *> *cacheMethods = cacheDict[apiName.spacename];
    if (cacheMethods) {
        // PASS
    } else {
        NSMutableArray<HCJsApiMethod *> *methodNameArray = [[NSMutableArray alloc] init];
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList([target class], &methodCount);
        for(int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            SEL sel = method_getName(method);
            NSString *methodName = [NSString stringWithCString:sel_getName(sel)
                                                      encoding:NSUTF8StringEncoding];
            NSArray *components = [methodName componentsSeparatedByString:kJsBridgeApiSelArgCountSeparateSymbol];
            NSUInteger numberOfParameter = components.count - 1;
            HCJsApiMethod *apiMethod = [[HCJsApiMethod alloc] initWithName:methodName
                                                                       sel:sel
                                                         numberOfParameter:numberOfParameter];
            [methodNameArray addObject:apiMethod];
        }
        cacheMethods = [methodNameArray copy];
        [cacheDict setObject:cacheMethods forKey:apiName.spacename];
    }
    HCJsBridgeMessageType messageType = [HCWebViewJsBridgeUtil judgeMessageTypeWithData:data
                                                                               callback:responseCallback];
    if (messageType == HCJsBridgeMessageTypeNoArgument) {
        SEL sel = [HCWebViewJsBridgeUtil noParameterfindSELWithApiName:apiName.name
                                                            methodList:cacheMethods];
        if (!sel) {
            return HCJsBridgeHandleApiResultTypeNotFoundMethod;
        }
        ((void(*)(id,SEL))objc_msgSend)(target, sel);
    } else {
        SEL sel = [HCWebViewJsBridgeUtil moreParameterfindSELWithApiName:apiName.name
                                                              methodList:cacheMethods];
        if (!sel) {
            return HCJsBridgeHandleApiResultTypeNotFoundMethod;
        }
        if (messageType == HCJsBridgeMessageTypeDataAndCallback) {
            ((void(*)(id,SEL,id,id))objc_msgSend)(target, sel, data, responseCallback);
        } else if (messageType == HCJsBridgeMessageTypeOnlyData) {
            ((void(*)(id,SEL,id))objc_msgSend)(target, sel, data);
        } else if (messageType == HCJsBridgeMessageTypeOnlyCallback) {
            ((void(*)(id,SEL,id))objc_msgSend)(target, sel, responseCallback);
        }
    }
    return HCJsBridgeHandleApiResultTypeSuccess;
}

+ (SEL)noParameterfindSELWithApiName:(NSString *)apiName methodList:(NSArray<HCJsApiMethod *> *)methodList {
    for (HCJsApiMethod *apiMethod in methodList) {
        if ([apiMethod.name isEqualToString:apiName]) {
            return apiMethod.selector;
        }
    }
    return nil;
}

+ (SEL)moreParameterfindSELWithApiName:(NSString *)apiName methodList:(NSArray<HCJsApiMethod *> *)methodList {
    NSString *newApiName = [NSString stringWithFormat:@"%@:", apiName];
    for (HCJsApiMethod *apiMethod in methodList) {
        if ([apiMethod.name hasPrefix:newApiName]) {
            return apiMethod.selector;
        }
    }
    return nil;
}

+ (HCJsBridgeMessageType)judgeMessageTypeWithData:(id)data
                                         callback:(HCJBResponseCallback)responseCallback {
    if ([HCWebViewJsBridgeUtil nonNull:data] && [HCWebViewJsBridgeUtil nonNull:responseCallback]) {
        return HCJsBridgeMessageTypeDataAndCallback;
    } else if ([HCWebViewJsBridgeUtil nonNull:data]) {
        return HCJsBridgeMessageTypeOnlyData;
    } else if ([HCWebViewJsBridgeUtil nonNull:responseCallback]) {
        return HCJsBridgeMessageTypeOnlyCallback;
    }
    return HCJsBridgeMessageTypeNoArgument;
}

+ (NSString *)generateCallbackId {
    NSString *uuid = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *callbackId = [NSString stringWithFormat:kJsBridgeNativeCallbackFormat, uuid];
    return callbackId;
}

@end
