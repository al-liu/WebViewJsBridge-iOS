//
//  HCWebViewJsBridgeUtil.h
//  Demo
//
//  Created by 刘海川 on 2019/9/21.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCJsApiName.h"
#import "HCJsApiMethod.h"


#ifdef DEBUG
    #define HCJBDebugLog(fmt, ...) NSLog((@"debug %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define HCJBDebugLog(...)
#endif
#define HCJBLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

typedef void (^HCJBResponseCallback)(id _Nullable responseData);
typedef void (^HCJBHandler)(id _Nullable data, HCJBResponseCallback _Nullable responseCallback);

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, HCJsBridgeHandleApiResultType) {
    HCJsBridgeHandleApiResultTypeSuccess = 0,
    HCJsBridgeHandleApiResultTypeNotFoundTarget,
    HCJsBridgeHandleApiResultTypeNotFoundMethod,
    HCJsBridgeHandleApiResultTypeErrorArgument
};

@interface HCWebViewJsBridgeUtil : NSObject

+ (BOOL)nonNull:(id)value;
+ (BOOL)isNull:(id)value;

+ (HCJsApiName *)resolveMessageName:(NSString *)name;
+ (HCJsBridgeHandleApiResultType)handleApiWithName:(HCJsApiName *)apiName
                                              data:(id)data
                                          callback:(HCJBResponseCallback)responseCallback
                                           apiDict:(NSDictionary *)apiDict
                                         cacheDict:(NSMutableDictionary *)cacheDict;

+ (NSString *)generateCallbackId;
@end

NS_ASSUME_NONNULL_END
