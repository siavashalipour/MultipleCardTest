//
//  CardModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RealmSwift
import RxBluetoothKit
import Realm

typealias Monitor = (realmCard: RealmCardPripheral, peripheral: Peripheral)

class RealmCardPripheral: Object {
    
    @objc dynamic var cardName: String = ""
    @objc dynamic var uuid: String = ""
    @objc dynamic var MACAddress: String = ""
    @objc dynamic var firmwareRevisionString: String = ""
    @objc dynamic var batteryLevel: String = ""
    @objc dynamic var connectionParameters: String = ""
    @objc dynamic var fsmParameters: String = ""
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    func update(for peripheral: Peripheral) {
        cardName = peripheral.name ?? ""
        uuid = peripheral.identifier.uuidString
    }
}

