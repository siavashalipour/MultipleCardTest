//
//  MFCardParameters.swift
//  MultipleCardTest
//
//  Created by Siavash on 30/5/18.
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
extension MFSFSMParameters: Equatable {
  static func ==(lhs: MFSFSMParameters, rhs: MFSFSMParameters) -> Bool {
    return (lhs.commissioned == rhs.commissioned &&
            lhs.fsmBehaviour == rhs.fsmBehaviour &&
            lhs.fsmConnectedTime == rhs.fsmConnectedTime &&
            lhs.fsmAdvertiseTimeShort == rhs.fsmAdvertiseTimeShort &&
            lhs.fsmAdvertiseTimeLong == rhs.fsmAdvertiseTimeLong &&
            lhs.fsmInactiveTime == rhs.fsmInactiveTime &&
            lhs.fsmAdvertisingIntervalShort == rhs.fsmAdvertisingIntervalShort &&
            lhs.fsmAdvertisingIntervalLong == rhs.fsmAdvertisingIntervalLong &&
            lhs.ledBrightness == rhs.ledBrightness
            )
  }
}
extension MFSFSMParameters {
  init() {
    self.commissioned = 1
    self.fsmBehaviour = 0
    self.fsmConnectedTime = 0
    self.fsmAdvertiseTimeShort = 0
    self.fsmAdvertiseTimeLong = 0
    self.fsmInactiveTime = 0
    self.fsmAdvertisingIntervalShort = 0
    self.fsmAdvertisingIntervalLong = 0
    self.ledBrightness = 0
  }
}

struct MFSMACAddress {
  let address: UInt8
}


struct MFSFindMonitorParameters {
  let toneValue: UInt8
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
  
  static let kCommissionedFSMHexStr = "0000005050010808080864"
}
