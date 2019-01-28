//
//  MOBLEManager.h
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NSObject+MultiDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@protocol MOBLEManagerDelegate <NSObject>

@optional
// 发现 peripheral
- (void)discoverPeripheral;
// peripheral 连接失败
- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
// peripheral 断开连接
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
// 发现 services
- (void)didDiscoverServices:(NSError *)error;
// 发现 characteristics
- (void)didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error;
// 发现 characteristic 值改变
- (void)didUpdateValueForCharacteristic;
// 发现 descriptions
- (void)didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
// 发现 description 值改变
- (void)didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error;
@end

@interface MOBLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *peripheralArr;
@property (nonatomic, strong) CBPeripheral *connectPer; // 点击连接的设备
@property (nonatomic, strong) NSMutableData *notifyData;
@property (nonatomic, strong) NSMutableArray *datas;
+ (instancetype)shareInstance;
- (void)startScan;  // 开始扫描
- (void)stopScan;   // 结束扫描
- (void)connectPer:(CBPeripheral *)per; // 连接 peripheral
- (void)cancelConnectionPer;  // 断开 peripheral 连接
- (void)discoverCharacteristicsForService:(CBService *)service; // 搜索 service 的 cha
- (void)readCharacteristic:(CBCharacteristic *)cha;       // 读
- (void)writeCharacteristic:(CBCharacteristic *)cha;      // 写
- (void)notifyCharacteristic:(CBCharacteristic *)cha;  // notify
- (void)discoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)cha; // 搜索 cha 的 description
- (void)writeValue:(NSData *)data forDescriptor:(CBDescriptor *)descriptor; // 给 description 写数据

- (NSURL *)getAndCreatePlayableFileFromPcmData:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
