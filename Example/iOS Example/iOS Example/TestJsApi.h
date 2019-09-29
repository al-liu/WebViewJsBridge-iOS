//
//  TestJsApi.h
//  Demo
//
//  Created by 刘海川 on 2019/9/29.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TestJsApiDelegate <NSObject>

@optional
- (NSString *)alertCancelResponseData;

@end

@interface TestJsApi : NSObject

@property (nonatomic, weak) UIViewController<TestJsApiDelegate> *context;

@end

NS_ASSUME_NONNULL_END
