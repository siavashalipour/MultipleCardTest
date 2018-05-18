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

class PeripheralInfoViewModel {
    
    private var ds: [PeripheralInfoCellData] = []
    
    private var selectedPeripheral: RealmCardPripheral
    
    init(with peripheral: RealmCardPripheral) {
        self.selectedPeripheral = peripheral
        var item = PeripheralInfoCellData.init(title: "Battery", subtitle: peripheral.batteryLevel + "%")
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "MACAddress", subtitle: peripheral.MACAddress)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Firmware", subtitle: peripheral.firmwareRevisionString)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "FSM", subtitle: peripheral.fsmParameters)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Connection", subtitle: peripheral.connectionParameters)
        ds.append(item)
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
