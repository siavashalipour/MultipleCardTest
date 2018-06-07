//
//  MFServices.swift
//  MultipleCardTest
//
//  Created by Siavash on 16/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//
import RxBluetoothKit
import Foundation
import CoreBluetooth


enum DeviceService: String, ServiceIdentifier {
  case deviceInformation = "180A"
  case battery = "180F"
  case ota = "FEF5"
  case safedome = "AAA0"
  case ia = "1802"
  
  var uuid: CBUUID {
    return CBUUID(string: self.rawValue)
  }
}

enum DeviceCharacteristic: String, CharacteristicIdentifier {
  // Battery Service
  case batteryLevel = "2A19"
  // Device information
  case manufacturerName = "2A29"
  case modelNumber = "2A24"
  case hardwareRevisionString = "2A27"
  case firmwareRevisionString = "2A26"
  case systemId = "2A23"
  case pnpId = "2A50"
  
  // case ota service
  case otaMemoryType = "8082CAA8-41A6-4021-91C6-56F9B954CC34"
  case otaMemoryParams = "724249F0-5EC3-4B5F-8804-42345AF08651"
  case otaMemoryInfo = "6C53DB25-47A1-45FE-A022-7C92FB334FD4"
  case otaPatchLength = "9D84B9A3-000C-49D8-9183-855B673FDA31"
  case otaPatchData = "457871E8-D516-4CA1-9116-57D0B17B9CB2"
  case otaStatus = "5F78DF94-798C-46F5-990A-B3EB6A065C88"
  
  // case safedome services
  case fsmParameters = "2A30" // state machine params
  case connectionParameters = "2A31" // BLE comm parameters
  case cardOff = "2A15"
  case LED = "2A14" // reference time info
  case OADTrigger = "2A0F" // local time info
  case MACAddress = "2A0D" // DST offset
  
  // case iaservice
  case findMonitorParameters = "2A06"
  
  var uuid: CBUUID {
    return CBUUID(string: self.rawValue)
  }
  //Service to which characteristic belongs
  var service: ServiceIdentifier {
    switch self {
    case .batteryLevel:
      return DeviceService.battery
    case .manufacturerName, .modelNumber, .hardwareRevisionString, .firmwareRevisionString, .systemId, .pnpId:
      return DeviceService.deviceInformation
    case .otaMemoryType, .otaMemoryParams, .otaMemoryInfo, .otaPatchLength, .otaPatchData, .otaStatus:
      return DeviceService.ota
    case .fsmParameters, .connectionParameters, .cardOff, .LED, .OADTrigger, .MACAddress:
      return DeviceService.safedome
    case .findMonitorParameters:
      return DeviceService.ia
    }
  }
}

