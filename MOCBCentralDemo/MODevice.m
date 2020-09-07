//
//  MODevice.m
//  MOCBCentralDemo
//
//  Created by moxiaoyan on 2020/8/14.
//  Copyright © 2020 moxiaoyan. All rights reserved.
//

#import "MODevice.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "NSData+HexRepresentation.h"
#import "CSRBLEUtil.h"
#define STANDARD_LENGTH 23

@implementation MODevice

- (id)initWithCBPeripheral:(CBPeripheral *)cbPeripheral
         advertisementData:(NSDictionary *)dict
                      rssi:(NSNumber *)rssi {
  if (self = [super init]) {
    _peripheral = cbPeripheral;
    _advertisementData = dict;
    _signalStrength = rssi;
    _isDataLengthExtensionSupported = false;
    _maximumWriteLength = STANDARD_LENGTH;
    _maximumWriteWithoutResponseLength = STANDARD_LENGTH;
    // 解析 manufacture data
    // mobvoi_id:2 mac:6 (mac:6) 电量:3 类型/状态:1 随机码/颜色:1 phone:1 名字/按键:1 accountID:4 充电/列表:1 (pro/standard)
    // mobvoi_id:2 mac:6 (会插入6位0) 电量:3 类型/状态:1 随机码/颜色:1 phone:1 名字/按键:1 accountID:4 充电/列表:1 (plus)
    if ([self manufacturerData] != nil) {
      NSMutableData *data = [[self manufacturerData] mutableCopy];
      if (data.length < 26) {
        [data replaceBytesInRange:NSMakeRange(8, 0) withBytes:NULL length:6];
      }
      // mobvoiID
      NSData *tempData = [data subdataWithRange:NSMakeRange(0, sizeof(uint8_t)*2)];
      _mobvoiId = [MODevice stringWithData:tempData];
      
      if ([_mobvoiId isEqualToString:@"a7fd"]) {
        _isEuropa = YES;
        _distance = [self distanceWithTxPower:-45];
        [self tidyData:data];
        if (_type == 3 || _type == 4) {
          _isSubMac = NO;
          _popBattery = YES;
        }
      } else {
        _isEuropa = NO;
      }
    } else {
      _isEuropa = NO;
    }
  }
  return self;
}

- (void)tidyData:(NSData *)data {
  NSData *tempData;
  // currentMacAddress
  tempData = [data subdataWithRange:NSMakeRange(2, sizeof(uint8_t) * 6)];
  _currentMacAddress = [MODevice macAddressStringWithData:tempData];
  // 是否为副耳
  tempData = [data subdataWithRange:NSMakeRange(7, sizeof(uint8_t))];
  _isSubMac = [CSRBLEUtil intValue:tempData] % 2 == 0;
  // anotherMacddress
  tempData = [data subdataWithRange:NSMakeRange(8, sizeof(uint8_t) * 6)];
  _anotherMacAddress = [MODevice macAddressStringWithData:tempData];
  // 电量: 左耳 右耳 充电盒
  uint8_t valueRequest = 0;
  [data getBytes:&valueRequest range:NSMakeRange(14, sizeof(uint8_t))];
  _batteryLeft = valueRequest;
  [data getBytes:&valueRequest range:NSMakeRange(15, sizeof(uint8_t))];
  _batteryRight = valueRequest;
  [data getBytes:&valueRequest range:NSMakeRange(16, sizeof(uint8_t))];
  _batteryBox = valueRequest;
  // 类型 / 状态
  [data getBytes:&valueRequest range:NSMakeRange(17, sizeof(uint8_t))];
  self.popBattery = (valueRequest & 0xf0) >> 4; // 高4位：状态
  self.type = valueRequest & 0x0f; // 低4位：type
  // 颜色
  [data getBytes:&valueRequest range:NSMakeRange(18, sizeof(uint8_t))];
  self.code = (valueRequest & 0xf0) >> 4;// 高4位：随机码
  self.color = valueRequest & 0x0f; // 低4位：color
  // phone
  [data getBytes:&valueRequest range:NSMakeRange(19, sizeof(uint8_t))];
  _phone = valueRequest == 0;
  // 名字/按键 00 changeName isKeypress
  [data getBytes:&valueRequest range:NSMakeRange(20, sizeof(uint8_t))];
  NSInteger nameValue = valueRequest;
  _isChangeName = nameValue == 2 || nameValue == 3;
  _isKeypress = nameValue == 1 || nameValue == 3;
  // accountID
  NSMutableData *accountIDData = [NSMutableData data];
  [accountIDData appendData:[data subdataWithRange:NSMakeRange(24, sizeof(uint8_t))]];
  [accountIDData appendData:[data subdataWithRange:NSMakeRange(23, sizeof(uint8_t))]];
  [accountIDData appendData:[data subdataWithRange:NSMakeRange(22, sizeof(uint8_t))]];
  [accountIDData appendData:[data subdataWithRange:NSMakeRange(21, sizeof(uint8_t))]];
  _accountId = [MODevice stringWithData:accountIDData];
  // 充电/列表
  [data getBytes:&valueRequest range:NSMakeRange(25, sizeof(uint8_t))];
  NSInteger classicValue = valueRequest;
  _isCharging = classicValue == 2 || classicValue == 3;
  _classicList = classicValue == 1 || classicValue == 3;
  
  if ([_currentMacAddress isEqualToString:@"8c:91:09:57:1f:c7"] ||
      [_currentMacAddress isEqualToString:@"00:00:ab:cd:b1:e1"]) { //@"8c:91:09:58:41:d0"
    NSLog(@"europa:===========================================");
    NSLog(@"europa: %@ %@ %ld-changeName:%d press:%d %ld-charging:%d classic:%d", _currentMacAddress, _anotherMacAddress, (long)nameValue, _isChangeName, _isKeypress, (long)classicValue, _isCharging, _classicList);
    NSLog(@"europa: left:%i right:%i box:%i mobvoiID:%@ type:%ld accountId:%@", _batteryLeft, _batteryRight, _batteryBox, _mobvoiId, (long)_type, _accountId);
    NSLog(@"europa: _phone:%i distance:%f code:%d", _phone, _distance, self.code);
    NSLog(@"europa:===========================================");
  }
}

+ (NSString *)stringWithData:(NSData *)data {
  NSString *string = [data hexString];
  return string.length > 0 ? string : @"";
}

- (BOOL)isConnected {
    if (_peripheral) {
        return (_peripheral.state == CBPeripheralStateConnected);
    }
    
    return NO;
}

- (BOOL)checkDLE {
    if (@available(iOS 9, *)) {
        _maximumWriteLength = [_peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse];
        _maximumWriteWithoutResponseLength = [_peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
        _isDataLengthExtensionSupported = (_maximumWriteLength > STANDARD_LENGTH);
    }
    
    return _isDataLengthExtensionSupported;
}

- (NSData *)manufacturerData {
  if (_advertisementData && _advertisementData[@"kCBAdvDataManufacturerData"]) {
    NSData *data = _advertisementData[@"kCBAdvDataManufacturerData"];
    if (data.length == 26 || data.length == 20) {
      return data;
    }
  }
  return nil;
}

+ (NSString *_Nullable)macAddressStringWithData:(NSData *_Nullable)data {
  if (data.length < 5) {
    return nil;
  }
  // mac地址
  NSArray *orderNumber = @[@(0), @(1), @(2), @(3), @(4), @(5)];
  NSMutableString *macAddress = [NSMutableString string];
  for (NSNumber *index in orderNumber) {
    NSData *numberData = [data subdataWithRange:NSMakeRange(index.intValue, sizeof(uint8_t))];
    NSString *numberStr = [numberData hexString];
    [macAddress appendString:numberStr];
    if (index.integerValue < orderNumber.count - 1) {
      [macAddress appendString:@":"];
    }
  }
  macAddress = macAddress.lowercaseString.copy;
  return macAddress;
}

//+ (NSString *)decodeDeviceTokenSince13:(NSData *)deviceToken{
//  if (![deviceToken isKindOfClass:[NSData class]]) return @"";
//  const unsigned *tokenBytes = [deviceToken bytes];
//  NSMutableString *hex = [NSMutableString new];
//  for (NSInteger i = 0; i < deviceToken.length; i++ ) {
//    [hex appendFormat:@"%02x", tokenBytes[i]];
//  }
//  return hex.copy;
//}

- (double)distanceWithTxPower:(NSInteger)power {
  double rssi = self.signalStrength.doubleValue;
  int txPower = power; // [-127, 126]
  // use coefficient values from spreadsheet for iPhone 4S
  double coefficient1 = 2.922026; // multiplier
  double coefficient2 = 6.672908; // power
  double coefficient3 = -1.767203; // intercept
  if (rssi == 0) {
    return -1.0; // if we cannot determine accuracy, return -1.0
  }
  double ratio = rssi * 1.0 / txPower;
  double distance;
  if (ratio < 1.0) {
    distance = pow(ratio,10);
  } else {
    distance = (coefficient1) * pow(ratio, coefficient2) + coefficient3;
  }
  if (distance < 0.1) {
//    DDLogDebug(@"Low distance");
  }
  _distance = distance;
  return distance;
}

@end
