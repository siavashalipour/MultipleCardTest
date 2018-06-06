//
//  RealmManager.swift
//  MultipleCardTest
//
//  Created by Siavash on 1/6/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RealmSwift
import RxBluetoothKit

struct RealmManager {
    
    static let shared = RealmManager()
    
    private let realm = try! Realm()
    
    func addOrUpdate(monitor: Monitor) {
        let model: RealmCardPripheral
        if let anItem = realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: monitor.peripheral.identifier.uuidString) {
            model = anItem
        } else {
            model = RealmCardPripheral()
        }
        let card = monitor.realmCard
        try! realm.write {
            model.cardName = card.cardName
            if model.uuid == "" { // since this is the primary key we need to make sure that it is the first and only time that we set it
                model.uuid = card.uuid
                model.MACAddress = card.MACAddress
                model.batteryLevel = card.batteryLevel
                model.connectionParameters = card.connectionParameters
                model.fsmParameters = card.fsmParameters
            }
            
            if card.firmwareRevisionString != "" {
                model.firmwareRevisionString = card.firmwareRevisionString
            }
            
            realm.add(model, update: true)
        }
    }
    func deleteFromRealm(monitor: Monitor) {
        if let objectToDelete = realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: monitor.peripheral.identifier.uuidString) {
            try! realm.write {
                realm.delete(objectToDelete)
            }
        }
    }
    func beginWrite() {
        try? realm.commitWrite()
        realm.beginWrite()
    }
    func commitWrite() {
        try? realm.commitWrite()
    }
    func getRealmObject(for monitor: Monitor) -> RealmCardPripheral? {
        return realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: monitor.peripheral.identifier.uuidString)
    }
    func getRealmObject(for peripheral: Peripheral) -> RealmCardPripheral? {
        return realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: peripheral.identifier.uuidString)
    }
    func fetchAllMonitors() -> Results<RealmCardPripheral>? {
        return realm.objects(RealmCardPripheral.self)
    }
    
}
