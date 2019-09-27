//
//  HCJsApiMethod.h
//  Demo
//
//  Created by 刘海川 on 2019/9/20.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HCJsApiMethod : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) NSUInteger numberOfParameter;

- (instancetype)initWithName:(NSString *)name
                         sel:(SEL)selector
           numberOfParameter:(NSUInteger)numberOfParameter;

@end

NS_ASSUME_NONNULL_END
