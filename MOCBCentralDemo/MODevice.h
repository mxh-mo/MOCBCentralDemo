//
//  MODevice.h
//  MOCBCentralDemo
//
//  Created by moxiaoyan on 2020/8/14.
//  Copyright © 2020 moxiaoyan. All rights reserved.
//  出门问问 耳机广播数据

#import <Foundation/Foundation.h>
@class CBPeripheral;

NS_ASSUME_NONNULL_BEGIN

@interface MODevice : NSObject

/// @brief The CBPeripheral
@property (nonatomic) CBPeripheral * _Nullable peripheral;

/// @brief The advertisement data dictionary
@property (nonatomic) NSDictionary * _Nullable advertisementData;

/// @brief The signal strength upon discovery
@property (nonatomic) NSNumber * _Nullable signalStrength;

/// @brief Is DLE supported on this peripheral
@property (nonatomic) BOOL isDataLengthExtensionSupported;

/// @brief The maximum write length
@property (nonatomic) NSUInteger maximumWriteLength;

/// @brief The maximum write length
@property (nonatomic) NSUInteger maximumWriteWithoutResponseLength;

@property (nonatomic, assign) BOOL isEuropa;            // 是否为2代耳机
@property (nonatomic, assign) BOOL isChangeName;        // 是否修改过名字
@property (nonatomic, assign) BOOL isKeypress;          // 是否按键（断开之前的连接，进入配对）
@property (nonatomic, assign) BOOL isCharging;          // 是否都在盒中充电
@property (nonatomic, assign) BOOL classicList;         // 经典蓝牙回连列表：YES:不空  NO:空
@property (nonatomic, assign) BOOL isSubMac;            // mac地址最后一位是偶数：副耳
@property (nonatomic, assign) BOOL popBattery;          // 在盒开盖：弹电量
@property (nonatomic, assign) BOOL phone;               // 需要回连手机
@property (nonatomic, assign) double distance;          // 距离：<=60cm才处理
@property (nonatomic, assign) NSInteger type;           // 1:Pro 2:Standard 3:Plus
@property (nonatomic, assign) NSInteger batteryBox;
@property (nonatomic, assign) NSInteger batteryLeft;
@property (nonatomic, assign) NSInteger batteryRight;
@property (nonatomic, assign) NSInteger color;
@property (nonatomic, assign) NSInteger code;           // 随机码
@property (nonatomic, copy) NSString * _Nullable mobvoiId;
@property (nonatomic, copy) NSString * _Nullable accountId;
@property (nonatomic, copy) NSString * _Nullable currentMacAddress;
@property (nonatomic, copy) NSString * _Nullable anotherMacAddress;

- (id)initWithCBPeripheral:(CBPeripheral *)cbPeripheral
         advertisementData:(NSDictionary *)dict
                      rssi:(NSNumber *)rssi;

@end

NS_ASSUME_NONNULL_END
