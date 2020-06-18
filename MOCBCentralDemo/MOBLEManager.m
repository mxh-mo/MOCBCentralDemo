//
//  MOBLEManager.m
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import "MOBLEManager.h"
#define kSaveDataFileName @"/ticpod_ble_data"
#define kSaveWavDataFileName @"/ticpod_ble_wav_data"

@implementation MOBLEManager {
  int _index;
}

+ (instancetype)shareInstance {
  static MOBLEManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[MOBLEManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)setNotifyData:(NSMutableData *)notifyData {
  _notifyData = notifyData;
  NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  NSString *filePath = [path stringByAppendingString:kSaveDataFileName];
  [NSKeyedArchiver archiveRootObject:_notifyData toFile:filePath];
}

- (void)startScan {
  self.peripheralArr = [NSMutableArray array];
  [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
}

- (void)stopScan {
  [_centralManager stopScan];
}

#pragma mark - 连接蓝牙
- (void)connectPer:(CBPeripheral *)per {
  [self cancelConnectionPer];
  [_centralManager connectPeripheral:per options:nil];
}

#pragma mark - 断开蓝牙
- (void)cancelConnectionPer {
  if (self.connectPer) {
    [_centralManager cancelPeripheralConnection:self.connectPer];
    self.connectPer = nil;
  }
}

#pragma mark - 搜索 `characteristic`
- (void)discoverCharacteristicsForService:(CBService *)service {
  [self.connectPer discoverCharacteristics:nil forService:service];
}

#pragma mark - 读 'characteristic'
- (void)readCharacteristic:(CBCharacteristic *)cha {
  [self.connectPer readValueForCharacteristic:cha];
}

#pragma mark - 写 `characteristic`
- (void)writeCharacteristic:(CBCharacteristic *)cha {
  uint16_t val = 0x0000;
  NSData *data = [NSData dataWithBytes:(void *)&val length:sizeof(val)];
  [self.connectPer writeValue:data forCharacteristic:cha type:CBCharacteristicWriteWithResponse];
}

#pragma mark - notify 'characteristic'
- (void)notifyCharacteristic:(CBCharacteristic *)cha {
  self.notifyData = [[NSMutableData alloc] init];
  [self.connectPer setNotifyValue:YES forCharacteristic:cha];
}

#pragma mark - 搜索 `characteristic` 的 `descriptor`
- (void)discoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)cha {
  [self.connectPer discoverDescriptorsForCharacteristic:cha];
}

#pragma mark - 给 description 写数据
- (void)writeValue:(NSData *)data forDescriptor:(CBDescriptor *)descriptor {
  [self.connectPer writeValue:data forDescriptor:descriptor];
  // 回调是 didWriteValueForCharacteristic 方法
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  switch (central.state) {
    case CBCentralManagerStateUnknown: NSLog(@"CBCentralManagerStateUnknown"); break;
    case CBCentralManagerStateResetting: NSLog(@"CBCentralManagerStateResetting"); break;
    case CBCentralManagerStateUnsupported: NSLog(@"CBCentralManagerStateUnsupported"); break;
    case CBCentralManagerStateUnauthorized: NSLog(@"CBCentralManagerStateUnauthorized"); break;
    case CBCentralManagerStatePoweredOff: NSLog(@"CBCentralManagerStatePoweredOff"); break;
    case CBCentralManagerStatePoweredOn: {
      NSLog(@"CBCentralManagerStatePoweredOn");
      [self startScan];
    } break;
    default: break;
  }
}
#pragma mark - 搜索到蓝牙
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
  __block BOOL newFind = YES;
//  NSLog(@"\n设备名称：%@", peripheral.name);
  [self.peripheralArr enumerateObjectsUsingBlock:^(CBPeripheral * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ( [obj.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString] ) {
      newFind = NO;
      *stop = YES;
    }
  }];
  if (newFind  && peripheral.name.length > 0) {
    [self.peripheralArr addObject:peripheral];
    [self operationDelegate:^(id delegate) {
      if ([delegate respondsToSelector:@selector(discoverPeripheral)]) {
        [delegate discoverPeripheral];
      }
    }];
  }
}

#pragma mark - 蓝牙连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  self.connectPer = peripheral;
  NSLog(@"%@:已连接 id:%@", peripheral.name, peripheral.identifier.UUIDString);
  self.connectPer.delegate = self;
  // 搜索 `peripheral` 的 `service`
  [self.connectPer discoverServices:nil]; // nil: 表示不过滤
}
#pragma mark - 蓝牙连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
  NSLog(@"%@:失败 id:%@ error:%@", peripheral.name, peripheral.identifier.UUIDString, error.description);
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didFailToConnectPeripheral:error:)]) {
      [delegate didFailToConnectPeripheral:peripheral error:error];
    }
  }];
}
#pragma mark - 蓝牙连接断开
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
  NSLog(@"%@:断开 id:%@ error:%@", peripheral.name, peripheral.identifier.UUIDString, error.description);
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didDisconnectPeripheral:error:)]) {
      [delegate didDisconnectPeripheral:peripheral error:error];
    }
  }];
}
#pragma mark - 搜索到 `service`
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  if (error) {
    NSLog(@"获取peripheral: %@ service失败: %@", peripheral.name, error.description);
    return;
  }
  self.connectPer = peripheral;
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didDiscoverServices:)]) {
      [delegate didDiscoverServices:error];
    }
  }];
}
#pragma mark - 搜索到 `characteristic`
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
  if (error) {
    NSLog(@"获取service: %@ characteristic失败: %@", service.UUID, error.description);
    return;
  }
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didDiscoverCharacteristicsForService:error:)]) {
      [delegate didDiscoverCharacteristicsForService:service error:error];
    }
  }];
}
#pragma mark - 订阅结果
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (error) {
    NSLog(@"订阅失败: %@", error.description);
  } else {
    self.notifyData = [[NSMutableData alloc] init];
    self.datas = [NSMutableArray array];
    _index = 0;
    NSLog(@"订阅成功");
  }
}
#pragma mark - `characteristic`数据更新
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (error) {
    NSLog(@"读取失败: %@", error.description);
    return;
  }
  NSData *data = [[NSMutableData alloc] initWithData:characteristic.value];
  NSLog(@"读取成功: value：%@ length:%lu", data, (unsigned long)data.length);

  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didUpdateValueForCharacteristic)]) {
      [delegate didUpdateValueForCharacteristic];
    }
  }];
  // save
  NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  NSString *filePath = [path stringByAppendingString:kSaveDataFileName];
  [NSKeyedArchiver archiveRootObject:_notifyData toFile:filePath];
  
}
// --- test
#pragma mark - 通知per继续发送
- (void)writeContinueCharacteristic:(CBCharacteristic *)cha {
  uint16_t val = 0x0000;
  NSData *data = [NSData dataWithBytes:(void *)&val length:sizeof(val)];
  [self.connectPer writeValue:data forCharacteristic:cha type:CBCharacteristicWriteWithResponse];
}
#pragma mark - 通知per从哪里开始发送
- (void)writeErrorCharacteristic:(CBCharacteristic *)cha {
  uint16_t payload_event = (uint16_t)_index & 0x0011;
  NSLog(@"payload_event :%hu", payload_event);
  NSData *data = [NSData dataWithBytes:(void *)&payload_event length:sizeof(payload_event)];
  [self.connectPer writeValue:data forCharacteristic:cha type:CBCharacteristicWriteWithResponse];

  // 验证是否正确
  data = [MOBLEManager dataWithReverse:data];
  NSInteger value = [MOBLEManager uint16Value:data offset:0];
  NSLog(@"写过去的value %ld", (long)value);
}


#pragma mark - 写`characteristic`结果
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (error) {
    NSLog(@"写失败: %@", error.description);
  } else {
    NSLog(@"写成功");
  }
}
#pragma mark - 收到 `characteristic` 的 `descriptor`
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (error) {
    NSLog(@"搜索 descriptor 失败: %@", error.description);
    return;
  }
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didDiscoverDescriptorsForCharacteristic:error:)]) {
      [delegate didDiscoverDescriptorsForCharacteristic:characteristic error:error];
    }
  }];
}
#pragma mark - `descriptor`数据更新
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
  if (error) {
    NSLog(@"读Description失败: %@", error.description);
  }
  [self operationDelegate:^(id delegate) {
    if ([delegate respondsToSelector:@selector(didUpdateValueForDescriptor:error:)]) {
      [delegate didUpdateValueForDescriptor:descriptor error:error];
    }
  }];
}

- (NSURL *)getAndCreatePlayableFileFromPcmData:(NSString *)filePath {
  NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  //wav文件的路径
  NSString *wavFilePath = [path stringByAppendingString:kSaveWavDataFileName];
  NSLog(@"PCM file path : %@",filePath); //pcm文件的路径
  
  FILE *fout;
  
  short NumChannels = 1;       //录音通道数
  short BitsPerSample = 16;    //线性采样位数
  int SamplingRate = 16000;     //录音采样率(Hz)
  int numOfSamples = (int)[[NSData dataWithContentsOfFile:filePath] length];
  
  int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
  short BlockAlign = NumChannels*BitsPerSample/8;
  int DataSize = NumChannels*numOfSamples*BitsPerSample/8;
  int chunkSize = 16;
  int totalSize = 46 + DataSize;
  short audioFormat = 1;
  
  if((fout = fopen([wavFilePath cStringUsingEncoding:1], "w")) == NULL)
  {
    printf("Error opening out file ");
  }
  
  fwrite("RIFF", sizeof(char), 4,fout);
  fwrite(&totalSize, sizeof(int), 1, fout);
  fwrite("WAVE", sizeof(char), 4, fout);
  fwrite("fmt ", sizeof(char), 4, fout);
  fwrite(&chunkSize, sizeof(int),1,fout);
  fwrite(&audioFormat, sizeof(short), 1, fout);
  fwrite(&NumChannels, sizeof(short),1,fout);
  fwrite(&SamplingRate, sizeof(int), 1, fout);
  fwrite(&ByteRate, sizeof(int), 1, fout);
  fwrite(&BlockAlign, sizeof(short), 1, fout);
  fwrite(&BitsPerSample, sizeof(short), 1, fout);
  fwrite("data", sizeof(char), 4, fout);
  fwrite(&DataSize, sizeof(int), 1, fout);
  
  fclose(fout);
  
  NSMutableData *pamdata = [NSMutableData dataWithContentsOfFile:filePath];
  NSFileHandle *handle;
  handle = [NSFileHandle fileHandleForUpdatingAtPath:wavFilePath];
  [handle seekToEndOfFile];
  [handle writeData:pamdata];
  [handle closeFile];
  
  return [NSURL URLWithString:wavFilePath];
}

+ (NSInteger)uint16Value:(NSData *)data offset:(NSInteger)offset {
  if (offset + sizeof(uint16_t) > data.length) return 0;
  const NSRange range = {offset, sizeof(uint16_t)};
  uint16_t value = 0;
  [data getBytes:&value range:range];
  return CFSwapInt16BigToHost(value);
}

+ (uint16_t)uint16FromBytes:(NSData *)fData {
//  NSAssert(fData.length == 2, @"uint16FromBytes: (data length != 2)");
  if (fData.length != 2) {
    NSLog(@"error uint16FromBytes: (data length != 2)");
  }
  NSData *data = [self dataWithReverse:fData];
  uint16_t val0 = 0;
  uint16_t val1 = 0;
  [data getBytes:&val0 range:NSMakeRange(0, 1)];
  [data getBytes:&val1 range:NSMakeRange(1, 1)];
  
  uint16_t dstVal = (val0 & 0xff) + ((val1 << 8) & 0xff00);
  return dstVal;
}

+ (NSData *)dataWithReverse:(NSData *)srcData {
  NSUInteger byteCount = srcData.length;
  NSMutableData *dstData = [[NSMutableData alloc] initWithData:srcData];
  NSUInteger halfLength = byteCount / 2;
  for (NSUInteger i=0; i<halfLength; i++) {
    NSRange begin = NSMakeRange(i, 1);
    NSRange end = NSMakeRange(byteCount - i - 1, 1);
    NSData *beginData = [srcData subdataWithRange:begin];
    NSData *endData = [srcData subdataWithRange:end];
    [dstData replaceBytesInRange:begin withBytes:endData.bytes];
    [dstData replaceBytesInRange:end withBytes:beginData.bytes];
  }
  return dstData;
}

@end
