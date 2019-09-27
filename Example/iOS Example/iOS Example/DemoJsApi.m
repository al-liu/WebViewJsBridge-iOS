//
//  DemoJsApi.m
//  Demo
//
//  Created by 刘海川 on 2019/9/19.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "DemoJsApi.h"
#import "HCWebViewJsBridge.h"

@implementation DemoJsApi

- (void)test1:(NSString *)data callback:(HCJBResponseCallback)callback {
    NSLog(@"调用到 native api test1, data is:%@", data);
    callback(@"来自 native api test1 的 callback.");
}

- (void)test2:(NSDictionary *)data {
    NSLog(@"调用到 native api:test2, data is:%@", data);
}

- (void)test3 {
    NSLog(@"调用到 native api:test3");
}

- (void)test4:(HCJBResponseCallback)callback {
    NSLog(@"调用到 native api:test4");
    callback(@"来自 native api test4 的 callback.");
}

@end
