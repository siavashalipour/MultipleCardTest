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

struct CardModel {    
    var cardName: String
    var uuid: String
    var isConnected: Bool
    var peripheral: Peripheral?
}

class RealmCardPripheral: Object {
    
    var cardName: String = ""
    var uuid: String = ""
    var MACAddress: String = ""
    var firmwareRevisionString: String = ""
    var batteryLevel: String = ""
    var connectionParameters: String = ""
    var fsmParameters: String = ""
    
    init(cardName: String, uuid: String, MACAddress: String, firmwareRevisionString: String, batteryLevel: String, connectionParameters: String, fsmParameters: String) {
        super.init()
        self.cardName = cardName
        self.uuid = uuid
        self.MACAddress = MACAddress
        self.firmwareRevisionString = firmwareRevisionString
        self.batteryLevel = batteryLevel
        self.connectionParameters = connectionParameters
        self.fsmParameters = fsmParameters
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}
