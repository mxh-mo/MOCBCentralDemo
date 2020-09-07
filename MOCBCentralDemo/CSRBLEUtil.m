//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRBLEUtil.h"

@implementation CSRBLEUtil

+ (BOOL)boolValue:(NSData *)data {
    if (!data) return NO;
    
    const BOOL *reportData = [data bytes];
    
    return reportData[0];
}

+ (NSInteger)intValue:(NSData *)data {
    if (!data) return 0;
    
    switch (data.length) {
        case 1: {
            uint8_t value = 0;
            
            [data getBytes:&value length:sizeof(value)];
            
            return value;
        }
        case 2: {
            uint16_t value = 0;
            
            [data getBytes:&value length:sizeof(value)];
            
            return value;
        }
        case 4: {
            uint32_t value = 0;
            
            [data getBytes:&value length:sizeof(value)];
            
            return value;
        }
        default:
            return 0;
    }
    
    return 0;
}

+ (NSInteger)uint8Value:(NSData *)data offset:(NSInteger)offset {
    if (offset + sizeof(uint8_t) > data.length) return 0;
    
    const NSRange range = {offset, sizeof(uint8_t)};
    const uint8_t *value = 0;
    
    [data getBytes:&value range:range];
    
    return *value;
}

+ (NSInteger)uint16Value:(NSData *)data offset:(NSInteger)offset {
    if (offset + sizeof(uint16_t) > data.length) return 0;
    
    const NSRange range = {offset, sizeof(uint16_t)};
    uint16_t value = 0;
    
    [data getBytes:&value range:range];
    
    return CFSwapInt16BigToHost(value);
}

+ (NSInteger)int16Value:(NSData *)data offset:(NSInteger)offset {
    if (offset + sizeof(int16_t) > data.length) return 0;
    
    const NSRange range = {offset, sizeof(int16_t)};
    int16_t value = 0;
    
    [data getBytes:&value range:range];
    
    return value;
}

+ (double)doubleValue:(NSData *)data offset:(NSInteger)offset {
    if (offset + sizeof(double) > data.length) return 0;
    
    const NSRange range = {offset, sizeof(double)};
    double value = 0;
    
    [data getBytes:&value range:range];
    
    return CFSwapInt16BigToHost(value);
}

+ (NSInteger)uint32Value:(NSData *)data offset:(NSInteger)offset {
    if (offset + sizeof(uint32_t) > data.length) return 0;
    
    const NSRange range = {offset, sizeof(uint32_t)};
    uint32_t value = 0;
    
    [data getBytes:&value range:range];
    
    return CFSwapInt32BigToHost(value);
}


+ (NSString *)stringValue:(NSData *)data {
    if (!data) return nil;
    
    NSString *string = [[NSString alloc]
                        initWithData:data
                        encoding:NSUTF8StringEncoding];
    
    return string;
}

+ (CBCharacteristic *)findCharacteristic:(CBPeripheral *)peripheral
                                    uuid:(NSString *)uuid {
    @try {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:uuid];
        
        for (CBService *service in peripheral.services) {
            for (CBCharacteristic *character in service.characteristics) {
                if ([character.UUID isEqual:characteristicUUID]) {
                    return character;
                }
            }
        }
    } @catch(NSException *ex) {
        return nil;
    }
    
    return nil;
}

+ (void)readCharacteristic:(CBPeripheral *)peripheral
                      uuid:(NSString *)uuid {
    CBCharacteristic *characteristic = [CSRBLEUtil findCharacteristic:peripheral
                                                                 uuid:uuid];
    // If found then request the values of interest
    if (characteristic) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

+ (void)writeCharacteristic:(CBPeripheral *)peripheral
                       uuid:(NSString *)uuid
                       data:(NSData *)data {
    CBCharacteristic *characteristic = [CSRBLEUtil findCharacteristic:peripheral
                                                                 uuid:uuid];
    // If found then request the values of interest
    if (characteristic) {
        [peripheral writeValue:data
             forCharacteristic:characteristic
                          type:CBCharacteristicWriteWithoutResponse];
    }
}

@end
