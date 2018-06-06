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

//struct CardModel {    
//    var name: String
//    var uuid: String
//    var isConnected: Bool
//    var MACAddress: String
//    var firmwareRevisionString: String
//    var batteryLevel: String
//    var connectionParameters: String
//    var fsmParameters: String
//    var peripheral: Peripheral?
//}
//extension CardModel {
//    
//    init(with peripheral: Peripheral) {
//        self.name = peripheral.name ?? ""
//        self.uuid = peripheral.identifier.uuidString
//        self.isConnected = false
//        self.MACAddress = ""
//        self.firmwareRevisionString = ""
//        self.batteryLevel = ""
//        self.connectionParameters = ""
//        self.fsmParameters = ""
//        self.peripheral = peripheral
//    }
//}

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

