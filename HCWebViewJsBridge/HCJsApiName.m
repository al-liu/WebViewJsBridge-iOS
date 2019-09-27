//
//  HCJsApiName.m
//  Demo
//
//  Created by 刘海川 on 2019/9/20.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "HCJsApiName.h"

@implementation HCJsApiName

- (instancetype)initWithName:(NSString *)name
                   spacename:(NSString *)spacename {
    self = [super init];
    if (self) {
        _name = name;
        _spacename = spacename;
    }
    return self;
}

@end
