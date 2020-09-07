//
//  NSData+HexRepresentation.m
//  One
//
//  Created by 宋晓光 on 2019/9/11.
//  Copyright © 2019 Mobvoi. All rights reserved.
//

#import "NSData+HexRepresentation.h"

@implementation NSData (HexRepresentation)

- (NSString *)hexString {
    const unsigned char *bytes = (const unsigned char *)self.bytes;
    NSMutableString *hex = [NSMutableString new];
    for (NSInteger i = 0; i < self.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return [hex copy];
}

@end
