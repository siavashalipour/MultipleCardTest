//
//  CardMisc.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth

// sizeof(MFSManufacturerData) pads the length so use this instead
let kSizeofMFSManufacturerData: CUnsignedLong = 3
struct MFSManufacturerData {
    let companyIdentifierCode: Character
    let commissioned: Bool = false
    let buttonPressed: Bool = false
    let unused: Int = 6
}

// sizeof(MFSConnectionParameters) pads the length so use this instead
let kSizeofMFSConnectionParameters: CUnsignedLong = 8
struct MFSConnectionParameters {
    let minimumConnectionInterval: UInt16
    let maximumConnectionInterval: UInt16
    let slaveLatency: UInt16
    let connectionSupervisionTimeout: UInt16
}


// sizeof(MFSFSMParameters) pads the length so use this instead
let kSizeofMFSFSMParameters: CUnsignedLong = 11
struct MFSFSMParameters {
    let commissioned: UInt8
    let fsmBehaviour: UInt8
    let fsmConnectedTime: UInt8
    let fsmAdvertiseTimeShort: UInt8
    let fsmAdvertiseTimeLong: UInt8
    let fsmInactiveTime: UInt8
    let fsmAdvertisingIntervalShort: UInt16
    let fsmAdvertisingIntervalLong: UInt16
    let ledBrightness: UInt8
}

// sizeof(MFSMACAddress) pads the length so use this instead
let kSizeofMFSMACAddress: CUnsignedLong = 6
struct MFSMACAddress {
    let address: UInt8
}

// sizeof(MFSFindMonitorParameters) pads the length so use this instead
let kSizeofMFSFindMonitorParameters: CUnsignedLong = 1
struct MFSFindMonitorParameters {
    let toneValue: UInt8
}


enum DeviceCharacteristic: String, CharacteristicIdentifier {
    case manufacturerName = "2A29"
    
    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
    //Service to which characteristic belongs
    var service: ServiceIdentifier {
        switch self {
        case .manufacturerName:
            return DeviceService.deviceInformation
        }
    }
}
enum DeviceService: String, ServiceIdentifier {
    case deviceInformation = "180A"
    
    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
}
