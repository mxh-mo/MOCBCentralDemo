//
//  ViewController.m
//  MOPeripheralDemo
//
//  Created by moxiaoyan on 2019/1/22.
//  Copyright © 2019 moxiaoyan. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) CBMutableService *service;
@end

@implementation ViewController

// 开始广播  停止广播
- (void)viewDidLoad {
  [super viewDidLoad];
  
//  CGFloat width = self.view.frame.size.width / 3;
//  UIButton *startAd = [UIButton buttonWithType:UIButtonTypeCustom];
//  [startAd setTitle:@"开始广播" forState:UIControlStateNormal];
//  [startAd setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//  startAd.frame = CGRectMake(0, 0, 100, 50);
//  startAd.center = CGPointMake(width, 100);
//  [startAd addTarget:self action:@selector(startAd) forControlEvents:UIControlEventTouchUpInside];
//  [self.view addSubview:startAd];
//
//  UIButton *stopAd = [UIButton buttonWithType:UIButtonTypeCustom];
//  [stopAd setTitle:@"停止广播" forState:UIControlStateNormal];
//  [stopAd setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
//  stopAd.frame = CGRectMake(0, 0, 100, 50);
//  stopAd.center = CGPointMake(width*2, 100);
//  [stopAd addTarget:self action:@selector(stopAd) forControlEvents:UIControlEventTouchUpInside];
//  [self.view addSubview:stopAd];
  
  self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
  

  CBUUID *serviceUUID = [CBUUID UUIDWithString: @"68753A44-4D6F-1226-9C60-0050E4C00089"];
  self.service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
  CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
  self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                                           properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyIndicate
                                                                value:nil
                                                          permissions:CBAttributePermissionsWriteable];
//  CBAttributePermissionsWriteEncryptionRequired
  self.service.characteristics = @[self.characteristic];
  // 发布
  [self.peripheralManager addService:self.service];

  // 广播: 这两个key的值最多有28字节(前台)
  [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey : @"moxiaoyanDemo",
                                             CBAdvertisementDataServiceUUIDsKey : @[self.service.UUID]}];
}

//- (void)startAd {
//
//}

//- (void)stopAd {
//  // 停止广播
//  [self.peripheralManager stopAdvertising];
//}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  switch (peripheral.state) {
    case CBManagerStateUnknown: NSLog(@"CBManagerStateUnknown"); break;
    case CBManagerStateResetting: NSLog(@"CBManagerStateResetting"); break;
    case CBManagerStateUnsupported: NSLog(@"CBManagerStateUnsupported"); break;
    case CBManagerStateUnauthorized: NSLog(@"CBManagerStateUnauthorized"); break;
    case CBManagerStatePoweredOff: NSLog(@"CBManagerStatePoweredOff"); break;
    case CBManagerStatePoweredOn: NSLog(@"CBManagerStatePoweredOn"); break;
    default: break;
  }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
  if (error) {
    NSLog(@"Error publishing service: %@", [error localizedDescription]);
  }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
  if (error) {
    NSLog(@"Error advertising: %@", [error localizedDescription]);
  }
}


#pragma mark - read request
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
  // 判断请求的UUID是否是匹配
  if ([request.characteristic.UUID isEqual:self.characteristic.UUID]) {
    // 判断请求所读的数据是否越界
    if (request.offset > self.characteristic.value.length) {
      // 响应请求 (越界)
      [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
      return;
    } else {
      // 设置请求的值
      NSRange range = NSMakeRange(request.offset, self.characteristic.value.length - request.offset);
      request.value = [self.characteristic.value subdataWithRange:range];
      // 响应请求 (成功)
      [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
  } else {
    // 响应请求 (未找到)
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorAttributeNotFound];
  }
}

#pragma mark - write request
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
  for (CBATTRequest *request in requests) {
    if ([request.characteristic.UUID isEqual:self.characteristic.UUID]) {
      // 判断请求所写的数据是否越界
      if (request.offset > self.characteristic.value.length) {
        // 响应时传的必须是第一个request!!!
        [self.peripheralManager respondToRequest:requests.firstObject withResult:CBATTErrorInvalidOffset];
      } else {
        // 写
        self.characteristic.value = request.value;
        // 响应请求 (成功)
        [self.peripheralManager respondToRequest:requests.firstObject withResult:CBATTErrorSuccess];
        NSLog(@"写成功 value:%@", request.value);
      }
    } else {
      [self.peripheralManager respondToRequest:requests.firstObject withResult:CBATTErrorAttributeNotFound];
    }
  }
}

#pragma mark - 接受到订阅
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  NSLog(@"Central subscribed to characteristic %@", characteristic);
  
  // TODO: 当值发生变化时, 通知订阅者
  NSData *updatedValue = self.characteristic.value;
  BOOL didSendValue = [self.peripheralManager updateValue:updatedValue forCharacteristic:self.characteristic onSubscribedCentrals:nil];
  NSLog(@"didSendValue: %d", didSendValue);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
  // 若上面通知返回失败, 则可在这个方法里, 重新通知
}





@end
