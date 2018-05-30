//
//  PeripheralInfoViewModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 18/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth
import RxSwift
import RxCocoa

class PeripheralInfoViewModel {
    
    private var ds: [PeripheralInfoCellData] = []
    
    private var selectedRealmPeripheral: RealmCardPripheral
    private var peripheral: Peripheral?
    private let updateManager: MFFirmwareUpdateManager = MFFirmwareUpdateManager.shared
    
    var shouldHideUpdateButtonObserver: Observable<Bool> {
        return shouldHideUpdateButtonSubject.asObservable()
    }
    
    private var shouldHideUpdateButtonSubject = BehaviorRelay(value: false)
    
    init(with realmPeripheral: RealmCardPripheral, peripheral: Peripheral?) {
        self.selectedRealmPeripheral = realmPeripheral
        var item = PeripheralInfoCellData.init(title: "Battery", subtitle: realmPeripheral.batteryLevel + "%")
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "MACAddress", subtitle: realmPeripheral.MACAddress)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Firmware", subtitle: realmPeripheral.firmwareRevisionString)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "FSM", subtitle: realmPeripheral.fsmParameters)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Connection", subtitle: realmPeripheral.connectionParameters)
        ds.append(item)
        self.peripheral = peripheral
        
    }
    public func bind() {
        shouldHideUpdateButtonSubject = BehaviorRelay(value: updateManager.latestFirmwareDataOnDiskVersion == selectedRealmPeripheral.firmwareRevisionString)
    }
    func numberOfItems() -> Int {
        return ds.count
    }
    func item(at indexPath: IndexPath) -> PeripheralInfoCellData? {
        if indexPath.row < ds.count {
            return ds[indexPath.row]
        }
        return nil 
    }
}
