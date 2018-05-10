//
//  ClassA+category.m
//  BlockDemo
//
//  Created by 张诗健 on 2018/3/29.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "ClassA+category.h"

@implementation ClassA (category)

+ (void)initialize
{
    NSLog(@"%s",__FUNCTION__);
}

+ (void)load
{
    NSLog(@"%s",__FUNCTION__);
}


@end
