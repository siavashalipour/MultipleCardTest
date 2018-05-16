//
//  CharacteristicsViewModelType.swift
//  MultipleCardTest
//
//  Created by Siavash on 15/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {
    
    var characteristicsOutput: Observable<Result<Characteristic, Error>> { get }
    
    var characteristicWriteOutput: Observable<Result<Characteristic, Error>> { get }
    
    var characteristicReadOutput: Observable<Result<Characteristic, Error>> { get }
    
    var updatedValueAndNotificationOutput: Observable<Result<Characteristic, Error>> { get }
    
    func setSelected(characteristic: Characteristic)
    
    func triggerValueRead()
    
    func writeToCharacteristic(value: String)
    
    func setNotificationsState(enabled: Bool)
    
}

