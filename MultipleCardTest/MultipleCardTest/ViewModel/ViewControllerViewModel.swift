//
//  ViewControllerViewModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 18/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxBluetoothKit
import RxSwift
import RealmSwift

class ViewModel {
    let bleKit = AppDelegate.bluetoothKitService
    
    private let disposeBag = DisposeBag()
    // Get the default Realm
    private let realm = try! Realm()
    private var fetchedPeripherals: Results<RealmCardPripheral>?

    private var ds: [CardModel] = [] {
        didSet {
//            if newValue.count >= ds.count {
//                if let card = ds.last {
//                }
//            }
            dataUpdatedPublisher.onNext(Result.success(ds))
        }
    }
    var dataUpdatedObserver: Observable<Result<[CardModel], Error>> {
        return dataUpdatedPublisher.asObservable()
    }
    var disconnectObserver: Observable<Result<Peripheral, Error>> {
        return disconnectPublisher.asObservable()
    }
    var reconnectionObserver: Observable<Result<Peripheral, Error>> {
        return reconnectionPublisher.asObservable()
    }
    var readingCardObserver: Observable<Result<Bool, Error>> {
        return readingCardPublisher.asObservable()
    }
    private var dataUpdatedPublisher = PublishSubject<Result<[CardModel], Error>>()
    private var disconnectPublisher = PublishSubject<Result<Peripheral, Error>>()
    private var reconnectionPublisher = PublishSubject<Result<Peripheral, Error>>()
    private var readingCardPublisher = PublishSubject<Result<Bool, Error>>()
    
    func bind() {
        bleKit.scanningOutput.subscribe(onNext: { (result) in
            switch result {
            case .success(let scanned):
                self.add(peripheral: scanned.peripheral)
            case .error(let error):
                print("scannin error: \(error)")
                self.dataUpdatedPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("!scannin error: \(error)")
            self.dataUpdatedPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.disconnectionReasonOutput.subscribe(onNext: { (result) in
            switch result {
            case .success(let peripheral):
                print("disconnected from \(peripheral.0.identifier)")
                self.disconnectPublisher.onNext(Result.success(peripheral.0))
            case .error(let error):
                print("Disconnection error: \(error)")
                self.disconnectPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("!Disconnection error: \(error)")
            self.disconnectPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.reConnectionOutput.subscribe(onNext: { (result) in
            switch result {
            case .success(let peripheral):
                self.add(peripheral: peripheral)
                self.reconnectionPublisher.onNext(Result.success(peripheral))
            case .error(let error):
                print("REconnect error: \(error)")
                self.reconnectionPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("REconnect error: \(error)")
            self.reconnectionPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
    }
    private func readInfo(for card: CardModel) {
        bleKit.readBattery(for: card)
        bleKit.readMACAddress(for: card)
        bleKit.readFSMParameters(for: card)
        bleKit.readFirmwareVersion(for: card)
        bleKit.readConnectionParameters(for: card)
        var cardCopy = card
        readingCardPublisher.onNext(Result.success(true))
        let zipped = Observable.zip(bleKit.batteryObserver, bleKit.macAddressObserver, bleKit.fsmParamsObserver, bleKit.connectionParamsObserver, bleKit.firmwareVersionObserver) {
            return (battery: $0, macAddress: $1, fsm: $2, connection: $3, firmware: $4)
        }
        zipped.subscribe(onNext: { (battery, macAddress, fsm, connection, firmware) in
            switch battery {
            case .success(let battery):
                cardCopy.batteryLevel = battery
            case .error(_):
                break
            }
            switch macAddress {
            case .success(let macAddress):
                cardCopy.MACAddress = macAddress
            case .error(_):
                break
            }
            switch fsm {
            case .success(let fsm):
                cardCopy.fsmParameters = fsm
            case .error(_):
                break
            }
            switch connection {
            case .success(let connection):
                cardCopy.connectionParameters = connection
            case .error(_):
                break
            }
            switch firmware {
            case .success(let firmware):
                cardCopy.firmwareRevisionString = firmware
            case .error(_):
                break
            }
            self.addToRealm(card: cardCopy)
            self.readingCardPublisher.onNext(Result.success(false))
        }, onError: { (error) in
            
        }).disposed(by: disposeBag)
    }
    private func add(peripheral: Peripheral?) {
        let card = CardModel(name: "safedome", uuid: "\(peripheral!.identifier)", isConnected: true, MACAddress: "", firmwareRevisionString: "", batteryLevel: "", connectionParameters: "", fsmParameters: "", peripheral: peripheral)
        if !ds.contains(where: {
            $0.uuid == card.uuid
        }) {
            ds.append(card)
            bleKit.instantiatePeripheralConnectionObserver(for: card)
            addToRealm(card: card)
            readInfo(for: card)
        }
    }
    private func addToRealm(card: CardModel) {
        let model = RealmCardPripheral()
        model.cardName = card.name
        model.uuid = card.uuid
        model.MACAddress = card.MACAddress
        model.batteryLevel = card.batteryLevel
        model.firmwareRevisionString = card.firmwareRevisionString
        model.connectionParameters = card.connectionParameters
        model.fsmParameters = card.fsmParameters
        try! realm.write {
            realm.add(model, update: true)
        }
    }
    private func deleteFromRealm(card: CardModel) {
        if let objectToDelete = realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: card.uuid) {
            print("Realm Deleted \(objectToDelete.uuid)")
            try! realm.write {
                realm.delete(objectToDelete)
            }
        }
        
    }
    func getPeripheralsIfAny() {
        fetchedPeripherals = realm.objects(RealmCardPripheral.self)
    }
    func startScanning() {
        bleKit.stopScanning()
        bleKit.startScanning()
    }
    func reconnect() {
        guard let peripherals = fetchedPeripherals else {
            reconnectionPublisher.onNext(Result.error(BluetoothServicesError.peripheralNil))
            return
            
        }
        
        let uuidStrings: [String] = peripherals.map({
            return $0.uuid
        })
        if uuidStrings.count == 0 {
            reconnectionPublisher.onNext(Result.error(BluetoothServicesError.peripheralNil))
            return
        }
        var uuids: [UUID] = []
        for uuid in uuidStrings {
            print("Fetched \(uuid)")
            if let aUUID = UUID.init(uuidString: uuid) {
                uuids.append(aUUID)
            }
        }
        bleKit.tryReconnect(to: uuids)
    }
    func disconnect(at indexPath: IndexPath) {
        if indexPath.row > self.ds.count {
            return
        }
        self.deleteFromRealm(card: ds[indexPath.row])
        if let peripheral = self.ds[indexPath.row].peripheral {
            bleKit.disconnect(peripheral)
        }
        
        ds.remove(at: indexPath.row)
    }
    
    func numberOfItems() -> Int {
        return ds.count
    }
    func item(at indexPath: IndexPath) -> CardModel? {
        if indexPath.row < ds.count {
            return ds[indexPath.row]
        }
        return nil 
    }
    func realmObject(for card: CardModel) -> RealmCardPripheral? {
        return realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: card.uuid)
    }
}
