//
//  NSObject+MultiDelegate.h
//  One
//
//  Created by 莫晓卉 on 2018/11/18.
//  Copyright © 2018年 Mobvoi. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (MultiDelegate)

- (void)addDelegate:(id)delegate;

// 一般不需要手动移除代理对象，内部已经做了自动监听释放
- (void)removeDelegate:(id)delegate;

- (void)operationDelegate:(void(^)(id delegate))operation;

@end

