//
//  ScanResultsViewModelType.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift

protocol ScanResultsViewModelType {
    
    var scanningOutput: Observable<Result<ScannedPeripheral, Error>> { get }
    
    var bluetoothService: RxBluetoothKitService { get }
    
    var isScanning: Bool { get set }
    
    func scanAction()
    
}

