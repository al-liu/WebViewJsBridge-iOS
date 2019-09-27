//
//  HCJsApiName.h
//  Demo
//
//  Created by 刘海川 on 2019/9/20.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HCJsApiName : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *spacename;

- (instancetype)initWithName:(NSString *)name
                   spacename:(NSString *)spacename;

@end

NS_ASSUME_NONNULL_END
