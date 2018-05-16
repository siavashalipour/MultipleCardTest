//
//  PeripheralServicesViewModelType.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import RxBluetoothKit
import RxSwift
import Foundation

protocol PeripheralServicesViewModelType {
    
    var displayedPeripheral: Peripheral { get }
    
    var bluetoothService: RxBluetoothKitService { get }
    
    var servicesOutput: Observable<Result<Service, Error>> { get }
    
    var disconnectionOutput: Observable<Result<RxBluetoothKitService.Disconnection, Error>> { get }
    
    func discoverServices()
    
    func disconnect()
}

