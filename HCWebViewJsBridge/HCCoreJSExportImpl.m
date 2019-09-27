//
//  HCCoreJSExportImpl.m
//  Demo
//
//  Created by 刘海川 on 2019/9/17.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCCoreJSExportImpl.h"

@implementation HCCoreJSExportImpl

- (void)handleMessage:(NSString *)message {
    if (_delegate && [_delegate respondsToSelector:@selector(handleMessage:webThread:)]) {
        [_delegate handleMessage:message webThread:[NSThread currentThread]];
    }
}

- (void)handleResponseMessage:(NSString *)message {
    if (_delegate && [_delegate respondsToSelector:@selector(handleResponseMessage:webThread:)]) {
        [_delegate handleResponseMessage:message webThread:[NSThread currentThread]];
    }
}

- (void)handleStartupMessage:(NSString *)message {
    if (_delegate && [_delegate respondsToSelector:@selector(handleStartupMessageWithWebThread:)]) {
        [_delegate handleStartupMessageWithWebThread:[NSThread currentThread]];
    }
}

@end

