//
//  CardMisc.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation


struct MFSManufacturerData {
    let companyIdentifierCode: Character
    let commissioned: Bool = false
    let buttonPressed: Bool = false
    let unused: Int = 6
}


struct MFSConnectionParameters {
    let minimumConnectionInterval: UInt16
    let maximumConnectionInterval: UInt16
    let slaveLatency: UInt16
    let connectionSupervisionTimeout: UInt16
}



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


struct MFSMACAddress {
    let address: UInt8
}


struct MFSFindMonitorParameters {
    let toneValue: UInt8
}


