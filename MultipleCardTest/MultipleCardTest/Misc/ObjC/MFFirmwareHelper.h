//
//  MFFirmwareHelper.h
//  MultipleCardTest
//
//  Created by Siavash on 30/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MFFirmwareHelperDelegate
- (void)updateStateToMFS_OTA_State_WritePatchData;
- (void)updateStateToMFS_OTA_State_WritePatchEnd;
- (void)updateStateToMFS_OTA_State_WritePatchLength;
- (void)updateStateToMFS_OTA_State_Reboot;
- (void)updateStateToMFS_OTA_State_PatchCompleted;

- (void)writeOtaPatchDataPath:(NSData *)data;
- (void)loadPatchDataDone:(NSData *)data;
- (void)writePatchEndData:(NSData *)data;
- (void)writeDefaultConnectionParameters;

@end

@import CoreBluetooth;

@interface MFFirmwareHelper : NSObject
@property (nonatomic) NSMutableData *firmwareData;
@property (nonatomic) int blockStartByte;
@property (nonatomic) UInt16 blockSize;
@property (nonatomic, weak) id <MFFirmwareHelperDelegate> delegate;
+ (instancetype)shared;

- (char)getCharValueFor:(NSMutableData *)value;
- (NSData *)getMemDevData;
- (NSData *)getMemInfoValue;
- (NSData *)patchLenghtData;
- (void)writePatchData;
- (void)loadPatchData;
- (void)writePatchEnd;
- (NSData *)rebootCommandData;
@end
