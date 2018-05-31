//
//  MFFirmwareHelper.m
//  MultipleCardTest
//
//  Created by Siavash on 30/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

#import "MFFirmwareHelper.h"

typedef enum {
    MEM_BANK_OLDEST = 0,
    MEM_BANK_1      = 1,
    MEM_BANK_2      = 2,
} MEM_BANK;
typedef enum {
    MEM_TYPE_SUOTA_SPI            = 0x13
} MEM_TYPE;
typedef enum {
    P0_0 = 0x00,
    P0_1 = 0x01,
    P0_2 = 0x02,
    P0_3 = 0x03,
    P0_4 = 0x04,
    P0_5 = 0x05,
    P0_6 = 0x06,
    P0_7 = 0x07
} GPIO;

static char const kMISOAddress  = P0_5;
static char const kMOSIAddress  = P0_6;
static char const kCSAddress    = P0_3;
static char const kSCKAddress   = P0_0;
static UInt16 const kChunkSize  = 20;

@implementation MFFirmwareHelper


+ (instancetype)shared {
    static MFFirmwareHelper *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}
- (NSData *)getMemDevData {
    int memDevValue = (MEM_TYPE_SUOTA_SPI << 24) | (MEM_BANK_OLDEST & 0xFF);
    NSLog(@"Set SPOTA_MEM_DEV: %#010x", memDevValue);
    NSData *memDevData = [NSData dataWithBytes:&memDevValue length:sizeof(memDevValue)];
    return memDevData;
}
- (char)getCharValueFor:(NSData *)value {
    char charValue;
    [value getBytes:&charValue length:sizeof(char)];
    return charValue;
}

- (NSData *)patchLenghtData {
    NSData *patchLengthData = [NSData dataWithBytes:&_blockSize length:sizeof(_blockSize)];
    return patchLengthData;
}
-(void)loadPatchData {
    // Step 3 - Load patch data
    uint8_t crc_code = 0;
    
    const char *bytes = [self.firmwareData bytes];
    for (int i = 0; i < [self.firmwareData length]; i++) {
        crc_code ^= bytes[i];
    }
    
    NSLog(@"Checksum for file: %#4x", crc_code);
    
    [self.firmwareData appendBytes:&crc_code length:sizeof(uint8_t)];
    
    NSLog(@"Size: %d", (int) [self.firmwareData length]);
    
    _blockStartByte = 0;
    _blockSize = 240;
    [_delegate loadPatchDataDone:_firmwareData];
}
- (void)writePatchData {
    // Step 5
    // Send current block in chunks of 20 bytes
    int dataLength = (int) [self.firmwareData length];
    
    if (_blockStartByte == 0) {
        NSLog(@"Upload procedure started");
    }
    [_delegate updateStateToMFS_OTA_State_WritePatchData];
    
    int chunkStartByte = 0;
    
    while (chunkStartByte < _blockSize) {
        
        // Check if we have less than current block-size bytes remaining
        int bytesRemaining = _blockSize - chunkStartByte;
        int currChunkSize = bytesRemaining >= kChunkSize ? kChunkSize : bytesRemaining;
        
        NSLog(@"Sending bytes %d to %d (%d/%d) of %d", _blockStartByte + chunkStartByte + 1, _blockStartByte + chunkStartByte + currChunkSize, chunkStartByte + currChunkSize, _blockSize, dataLength);
        
        double progress = (double)(_blockStartByte + chunkStartByte + currChunkSize) / (double)dataLength;
        
        NSLog(@"%d%%", (int)(100 * progress));
        [_delegate progress:(int)(100 * progress)];
        // Send next n bytes of the patch
        char bytes[currChunkSize];
        [self.firmwareData getBytes:bytes range:NSMakeRange(_blockStartByte + chunkStartByte, currChunkSize)];
        NSData *patchData = [NSData dataWithBytes:bytes length:currChunkSize];
        
        // On to the chunk
        chunkStartByte += currChunkSize;
        
        //        // Check if we are passing the current block
        if (chunkStartByte >= self.blockSize) {
            // Prepare for next block
            self.blockStartByte += self.blockSize;
            
            int remainingBytes = dataLength - self.blockStartByte;
            if (remainingBytes == 0) {
                [_delegate updateStateToMFS_OTA_State_WritePatchEnd];
            } else if (remainingBytes < self.blockSize) {
                self.blockSize = remainingBytes;
                [_delegate updateStateToMFS_OTA_State_WritePatchLength];
            }
        }
        [_delegate writeOtaPatchDataPath:patchData];
    }
}
- (NSData *)getMemInfoValue {
    int memInfoValue = (kMISOAddress << 24) | (kMOSIAddress << 16) | (kCSAddress << 8) | kSCKAddress;
    NSLog(@"Set SPOTA_GPIO_MAP: %#010x", memInfoValue);
    NSData *memInfoData = [NSData dataWithBytes:&memInfoValue length:sizeof(memInfoValue)];
    return memInfoData;
}
-(void)writePatchEnd {
    [_delegate updateStateToMFS_OTA_State_Reboot];
    int suotaEnd = 0xFE000000;
    NSLog(@"Send SUOTA END command: %#010x", suotaEnd);
    NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(suotaEnd)];
    [_delegate writePatchEndData:suotaEndData];
}

- (NSData *)rebootCommandData {
    
//    [_delegate updateStateToMFS_OTA_State_PatchCompleted];
    int suotaEnd = 0xFD000000;
    NSLog(@"Send SUOTA REBOOT command: %#010x", suotaEnd);
    NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(suotaEnd)];
    return suotaEndData;
}
@end

