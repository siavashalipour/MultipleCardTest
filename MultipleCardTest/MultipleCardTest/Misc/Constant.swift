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
//        static let uuidsKey = "uuidsKey"
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
