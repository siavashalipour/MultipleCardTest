//
//  Constant.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxBluetoothKit

struct Constant {
    
    struct Constraints {
        static let horizontalSmall: CGFloat = 8.0
        
        static let horizontalDefault: CGFloat = 16.0
        
        static let verticalSmall: CGFloat = 8.0
        
        static let verticalDefault: CGFloat = 16.0
        
        static let verticalMedium: CGFloat = 20.0
        
        static let navigationBarHeight: CGFloat = 64.0
        
        static let smallWidth: CGFloat = 32.0
        
        static let smallHeight: CGFloat = 32.0
    }
    
    struct ImageRepo {
        static let bluetooth: UIImage = UIImage(named: "bluetooth")!
        
        static let bluetoothService: UIImage = UIImage(named: "bluetooth-service")!
    }
    
    struct Strings {
        static let defaultDispatchQueueLabel = "com.polidea.rxbluetoothkit.timer"
        static let uuidsKey = "uuidsKey"
        static let scanResultSectionTitle = "Scan Results"
        static let startScanning = "Start scanning"
        static let stopScanning = "Stop scanning"
        static let scanning = "Scanning..."
        static let servicesSectionTitle = "Discovered Services"
        static let characteristicsSectionTitle = "Discovered Characteristics"
        
        static let titleWrite = "Write"
        static let titleSuccess = "Success"
        static let titleRead = "Read"
        static let titleCancel = "Cancel"
        static let titleWriteValue = "Write value"
        static let titleOk = "OK"
        static let titleError = "Error"
        
        static let turnOffNotifications = "Turn OFF Notification"
        static let connect = "Connect"
        static let connected = "Connected"
        static let disconnect = "Disconnect"
        static let disconnected = "Disconnected"
        static let turnOnNotifications = "Turn ON Notification"
        static let hexValue = "Specify value in HEX to write"
        static let titleChooseAction = "Choose action"
        static let successfulWroteTo = "Successfully wrote value to:"
    }
    
    struct CardPeripheralUUID {
        static let deviceInformationService = "180A"
        static let firmwareVersion = "2A26"
        static let batteryService = "180F"
        static let batteryValue = "2A19"
        static let otaService = "FEF5"
        static let otaMemoryType = "8082CAA8-41A6-4021-91C6-56F9B954CC34"
        static let otaMemoryParams = "724249F0-5EC3-4B5F-8804-42345AF08651"
        static let otaMemoryInfo = "6C53DB25-47A1-45FE-A022-7C92FB334FD4"
        static let otaPatchLength = "9D84B9A3-000C-49D8-9183-855B673FDA31"
        static let otaPatchData = "457871E8-D516-4CA1-9116-57D0B17B9CB2"
        static let otaStatus = "5F78DF94-798C-46F5-990A-B3EB6A065C88"
        static let service = "AAA0"
        static let iaService = "1802"
        static let OADTrigger = "2A0F"
        static let fsmParameters = "2A30"
        static let connectionParameters = "2A31"
        static let cardOff = "2A15"
        static let MACAddress = "2A0D"
        static let LED = "2A14"
        static let findMonitorParameters = "2A06"
    }
}

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

struct CardParameters {
    static var kMFSConnectionParameters = MFSConnectionParameters(minimumConnectionInterval: 10, maximumConnectionInterval: 30, slaveLatency: 1, connectionSupervisionTimeout: 200)

    static var kMFSFSMParameters = MFSFSMParameters(commissioned: 1, fsmBehaviour: 0, fsmConnectedTime: 0, fsmAdvertiseTimeShort: 80, fsmAdvertiseTimeLong: 80, fsmInactiveTime: 1, fsmAdvertisingIntervalShort: 2056, fsmAdvertisingIntervalLong: 2056, ledBrightness: 100)

    static var kDecommissionFSMParameters = MFSFSMParameters(commissioned: 0, fsmBehaviour: 0, fsmConnectedTime: 0, fsmAdvertiseTimeShort: 80, fsmAdvertiseTimeLong: 80, fsmInactiveTime: 1, fsmAdvertisingIntervalShort: 2056, fsmAdvertisingIntervalLong: 2056, ledBrightness: 100)
    
    static var kMFSFindMonitorParameters = MFSFindMonitorParameters(toneValue: 2)

}
struct PathHelper {
    static func firmwareVersionPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.deviceInformationService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.firmwareVersion)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
        
    }
    static func batteryValuePath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.batteryService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.batteryValue)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaMemoryTypePath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaMemoryType)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaMemoryParamsPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaMemoryParams)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaMemoryInfoPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaMemoryInfo)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaPatchLengthPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaPatchLength)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaPatchDataPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaPatchData)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func otaStatusPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.otaService)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.otaStatus)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func OADTriggerPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.OADTrigger)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func fsmParametersPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.fsmParameters)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func connectionParametersPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.connectionParameters)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func cardOffPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.cardOff)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func MACAddressPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.MACAddress)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func LEDPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.service)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.LED)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
    static func findMonitorParametersPath() -> MFBPath {
        let service = CBUUID.init(string: Constant.CardPeripheralUUID.findMonitorParameters)
        let char = CBUUID.init(string: Constant.CardPeripheralUUID.iaService)
        return MFBPath(characteristicUUID: char, serviceUUID: service)
    }
}
