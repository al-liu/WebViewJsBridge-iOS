//
//  HCJsApiMethod.m
//  Demo
//
//  Created by 刘海川 on 2019/9/20.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCJsApiMethod.h"

@implementation HCJsApiMethod

- (instancetype)initWithName:(NSString *)name
                         sel:(SEL)selector
           numberOfParameter:(NSUInteger)numberOfParameter {
    self = [super init];
    if (self) {
        _name = name;
        _selector = selector;
        _numberOfParameter = numberOfParameter;
    }
    return self;
}


@end
