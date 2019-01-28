//
//  NSObject+MultiDelegate.m
//  One
//
//  Created by 莫晓卉 on 2018/11/18.
//  Copyright © 2018年 Mobvoi. All rights reserved.
//

#import "NSObject+MultiDelegate.h"
#import <objc/runtime.h>

#pragma mark <_CZWeakObjectBridge>
@interface _CZWeakObjectBridge : NSObject
@property (weak ,nonatomic) id weakObject;
- (instancetype)initWithWeakObj:(id)weakObject;
@end
@implementation _CZWeakObjectBridge
- (instancetype)initWithWeakObj:(id)weakObject {
  if (self = [super init]) {
    self.weakObject = weakObject;
  }
  return self;
}
@end

#pragma mark <_CZDellocMonitor>
@interface _CZDellocMonitor : NSObject
@property (weak ,nonatomic) id obj;
@property (copy ,nonatomic) void(^dellocCb)(id obj);
- (instancetype)initWithObj:(id)obj;
- (void)registerHandler:(void(^)(id obj))handler;
@end

@implementation _CZDellocMonitor
- (instancetype)initWithObj:(id)obj {
  if (self = [super init]) {
    self.obj = obj;
  }
  return self;
}

- (void)registerHandler:(void (^)(id))handler {
  self.dellocCb = handler;
}

- (void)dealloc {
  if (self.dellocCb) {
    self.dellocCb(self.obj);
  }
}

@end

static char DelegateBridgesKey;
static char DellocMonitorKey;
@implementation NSObject (MultiDelegate)

- (void)setDellocMonitor:(_CZDellocMonitor *)monitor {
  objc_setAssociatedObject(self, &DellocMonitorKey, monitor, OBJC_ASSOCIATION_RETAIN);
}

- (_CZDellocMonitor *)getDellocMonitor {
  return objc_getAssociatedObject(self, &DellocMonitorKey);
}

- (NSMutableArray<_CZWeakObjectBridge *> *)delegateBridges {
  NSMutableArray *delegateBridges = objc_getAssociatedObject(self, &DelegateBridgesKey);
  if (delegateBridges == nil) {
    delegateBridges = [NSMutableArray array];
    objc_setAssociatedObject(self, &DelegateBridgesKey, delegateBridges, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return delegateBridges;
}

- (void)addDelegate:(id)delegate {
  NSMutableArray *delegateBridges = [self delegateBridges];
  BOOL exits = NO;
  for (_CZWeakObjectBridge *bridge in delegateBridges) {
    if (bridge.weakObject == delegate) {
      exits = YES;
      break;
    }
  }
  if (exits) {
    return;
  }
  _CZWeakObjectBridge *bridge = [[_CZWeakObjectBridge alloc] initWithWeakObj:delegate];
  [delegateBridges addObject:bridge];
  _CZDellocMonitor *monitor = [[_CZDellocMonitor alloc] initWithObj:bridge];
  [monitor registerHandler:^(id obj) {
    if ([delegateBridges containsObject:obj]) {
      [delegateBridges removeObject:obj];
    }
  }];
  [delegate setDellocMonitor:monitor];
}

- (void)removeDelegate:(id)delegate {
  for (_CZWeakObjectBridge *bridge in [self delegateBridges]) {
    if (bridge.weakObject == delegate) {
      [[self delegateBridges] removeObject:bridge];
      break;
    }
  }
}

- (void)operationDelegate:(void (^)(id))operation {
  for (_CZWeakObjectBridge *bridge in [self delegateBridges]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      operation(bridge.weakObject);
    });
  }
}

@end
