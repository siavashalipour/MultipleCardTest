//
//  ScanResultsViewModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

final class ScanResultsViewModel: ScanResultsViewModelType {
    
    let bluetoothService: RxBluetoothKitService
    
    var scanningOutput: Observable<Result<ScannedPeripheral, Error>> {
        return bluetoothService.scanningOutput
    }
    
    var isScanning: Bool = false
    
    init(with bluetoothService: RxBluetoothKitService) {
        self.bluetoothService = bluetoothService
    }
    
    func scanAction() {
        if isScanning {
            bluetoothService.stopScanning()
        } else {
            bluetoothService.startScanning()
        }
        
        isScanning = !isScanning
    }
}

