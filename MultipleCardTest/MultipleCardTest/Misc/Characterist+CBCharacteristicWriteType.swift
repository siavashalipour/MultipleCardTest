//
//  Characterist+CBCharacteristicWriteType.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth

extension Characteristic {
    
    // A characteristic's properties can provide you information if it responds to a write operation. If it does, it can
    // be either responding to the operation or not. In this implementation it was decided to provide .withResponse if
    // it is the operation can be responded and ignoring .withoutResponse type.
    func determineWriteType() -> CBCharacteristicWriteType? {
        let writeType = self.properties.contains(.write) ? CBCharacteristicWriteType.withResponse :
            self.properties.contains(.writeWithoutResponse) ? CBCharacteristicWriteType.withoutResponse : nil
        
        return writeType
    }
}
