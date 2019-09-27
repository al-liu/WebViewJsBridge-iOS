//
//  HCCoreJSExportImpl.h
//  Demo
//
//  Created by 刘海川 on 2019/9/17.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCCoreJSExport.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HCCoreJSExportDelegate <NSObject>

- (void)handleMessage:(NSString *)message webThread:(nonnull NSThread *)webThread;

- (void)handleResponseMessage:(NSString *)message webThread:(nonnull NSThread *)webThread;

- (void)handleStartupMessageWithWebThread:(nonnull NSThread *)webThread;

@end

@interface HCCoreJSExportImpl : NSObject <HCCoreJSExport>

@property (nonatomic, weak) id <HCCoreJSExportDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
