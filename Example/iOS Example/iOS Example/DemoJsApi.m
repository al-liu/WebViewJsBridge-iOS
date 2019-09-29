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
    NSLog(@"Js call native api test1, data is:%@", data);
    callback(@"native api test1’callback.");
}

- (void)test2:(NSDictionary *)data {
    NSLog(@"Js native api:test2, data is:%@", data);
}

- (void)test3 {
    NSLog(@"Js native api:test3");
}

- (void)test4:(HCJBResponseCallback)callback {
    NSLog(@"Js native api:test4");
    callback(@"native api test4'callback.");
}

@end
