//
//  Constant.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import UIKit

struct Constant {
    
    struct Strings {
        static let defaultDispatchQueueLabel = "com.maxwellforest.rxbluetoothkit.timer"
    }
    
    struct PackageSizes {
        // sizeof(MFSManufacturerData) pads the length so use this instead
        static let kSizeofMFSManufacturerData: CUnsignedLong = 3
        // sizeof(MFSConnectionParameters) pads the length so use this instead
        static let kSizeofMFSConnectionParameters: CUnsignedLong = 8
        // sizeof(MFSFSMParameters) pads the length so use this instead
        static let kSizeofMFSFSMParameters: CUnsignedLong = 11
        // sizeof(MFSMACAddress) pads the length so use this instead
        static let kSizeofMFSMACAddress: CUnsignedLong = 6
        // sizeof(MFSFindMonitorParameters) pads the length so use this instead
        static let kSizeofMFSFindMonitorParameters: CUnsignedLong = 1
    }
}


struct CardParameters {
    
    static var kDefaultConnectionParameters = MFSConnectionParameters(minimumConnectionInterval: 1583, //1978.75ms
                                                                      maximumConnectionInterval: 1599, //1998.75ms
                                                                      slaveLatency: 0,
                                                                      connectionSupervisionTimeout: 600)  //6s
    
    static var kFastConnectionParameters = MFSConnectionParameters(minimumConnectionInterval: 10,
                                                                   maximumConnectionInterval: 30,
                                                                   slaveLatency: 1,
                                                                   connectionSupervisionTimeout: 200)

    static var kDefaultFSMParameters = MFSFSMParameters(commissioned: 1, //Yes
                                                        fsmBehaviour: 0, //FSM_BEHAVIOUR_LOOP_INACTIVE_FIRST
                                                        fsmConnectedTime: 0, //Don't disconnect
                                                        fsmAdvertiseTimeShort: 80, //16s
                                                        fsmAdvertiseTimeLong: 80, //16s
                                                        fsmInactiveTime: 1, //200ms
                                                        fsmAdvertisingIntervalShort: 2056, //1285ms
                                                        fsmAdvertisingIntervalLong: 2056, //1285ms
                                                        ledBrightness: 100) //Full brightness

    static var kDecommissionFSMParameters = MFSFSMParameters(commissioned: 0,
                                                             fsmBehaviour: 0,
                                                             fsmConnectedTime: 0,
                                                             fsmAdvertiseTimeShort: 80,
                                                             fsmAdvertiseTimeLong: 80,
                                                             fsmInactiveTime: 1,
                                                             fsmAdvertisingIntervalShort: 2056,
                                                             fsmAdvertisingIntervalLong: 2056,
                                                             ledBrightness: 100)
    
    static var kMFSFindMonitorParameters = MFSFindMonitorParameters(toneValue: 2)
}
