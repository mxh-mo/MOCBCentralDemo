//
//  MOSersViewController.h
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CBPeripheral;

NS_ASSUME_NONNULL_BEGIN

@interface MOSersViewController : UIViewController
@property (nonatomic, strong) CBPeripheral *per;
@end

NS_ASSUME_NONNULL_END
