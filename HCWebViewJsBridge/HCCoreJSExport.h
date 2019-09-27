//
//  HCCoreJSExport.h
//  Demo
//
//  Created by 刘海川 on 2019/9/17.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HCCoreJSExport <JSExport>

JSExportAs(handleMessage,
           - (void)handleMessage:(NSString *)message
           );

JSExportAs(handleResponseMessage,
           - (void)handleResponseMessage:(NSString *)message
           );

JSExportAs(handleStartupMessage,
           - (void)handleStartupMessage:(NSString *)message
           );


@end

NS_ASSUME_NONNULL_END
