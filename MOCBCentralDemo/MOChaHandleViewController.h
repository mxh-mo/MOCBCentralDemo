//
//  MOChaHandleViewController.h
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CBCharacteristic;

NS_ASSUME_NONNULL_BEGIN

@interface MOChaHandleViewController : UIViewController
- (void)setCha:(CBCharacteristic *)cha string:(NSString *)string;
@end

NS_ASSUME_NONNULL_END
