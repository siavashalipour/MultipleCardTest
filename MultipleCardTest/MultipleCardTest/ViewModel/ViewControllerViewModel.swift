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

class DashboardViewModel {
    
    private let bleKit = AppDelegate.bluetoothKitService
    
    private let disposeBag = DisposeBag()
    // Get the default Realm
    private let realm = try! Realm()
    private var fetchedPeripherals: Results<RealmCardPripheral>?

    private var ds: [CardModel] = []
    
    var dataUpdatedObserver: Observable<Result<[CardModel], Error>> {
        return dataUpdatedPublisher.asObservable()
    }
    var disconnectObserver: Observable<Result<Peripheral, Error>> {
        return disconnectPublisher.asObservable()
    }
    var reconnectionObserver: Observable<Result<CardModel, Error>> {
        return reconnectionPublisher.asObservable()
    }
    var readingCardObserver: Observable<Result<Bool, Error>> {
        return readingCardPublisher.asObservable()
    }
    var connectionToCardObserver: Observable<Result<Peripheral, Error>> {
        return connectionToCardPublisher.asObservable()
    }
    var commissionObserver: Observable<Result<Bool, Error>>  {
        return commissionPublisher.asObservable()
    }
    var unlinkCardObserver: Observable<Result<Bool, Error>> {
        return unlinkCardSubject.asObservable()
    }
    
    private var dataUpdatedPublisher = PublishSubject<Result<[CardModel], Error>>()
    private var disconnectPublisher = PublishSubject<Result<Peripheral, Error>>()
    private var reconnectionPublisher = PublishSubject<Result<CardModel, Error>>()
    private var readingCardPublisher = PublishSubject<Result<Bool, Error>>()
    private var connectionToCardPublisher = PublishSubject<Result<Peripheral, Error>>()
    private var commissionPublisher = PublishSubject<Result<Bool, Error>>()
    private var unlinkCardSubject = PublishSubject<Result<Bool, Error>> ()
    
    func bind() {
        bleKit.scanningOutput
            .subscribe(onNext: { (result) in
            switch result {
            case .success(let scanned):
                let card = CardModel(name: "\(scanned.peripheral.name ?? "")", uuid: "\(scanned.peripheral.identifier)", isConnected: true, MACAddress: "", firmwareRevisionString: "", batteryLevel: "", connectionParameters: "", fsmParameters: "", peripheral: scanned.peripheral)
                _ = scanned.peripheral.establishConnection().subscribe({ (event) in
                    if let peripheral = event.element {
                        print(peripheral.isConnected)
                        if peripheral.isConnected {
                            self.bleKit.startCardBinding(for: card)
                        }
                    }
                })

            case .error(let error):
                print("scanning error: \(error)")
                self.dataUpdatedPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("!scannin error: \(error)")
            self.dataUpdatedPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.cardBindingObserver.subscribe(onNext: { (result) in
            switch result {
            case .success(let card):
                print("Card flow binding success \(card)")
                self.add(card: card)
            case .error(let error):
                print("Card flow binding failed \(error)")
                self.dataUpdatedPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("Card flow binding failed \(error)")
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
            case .success(let card):
                self.add(card: card)
                self.reconnectionPublisher.onNext(Result.success(card))
            case .error(let error):
                print("REconnect error: \(error)")
                self.reconnectionPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            print("REconnect error: \(error)")
            self.reconnectionPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.unlinkingObserver.subscribe(onNext: { (result) in
            self.unlinkCardSubject.onNext(result)
        }, onError: { (error) in
            self.unlinkCardSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
    }

    private func add(card: CardModel, saveToRealm: Bool = true) {
        dataUpdatedPublisher.onNext(Result.success(ds))
        if !ds.contains(where: {
            $0.uuid == card.uuid
        }) {
            ds.append(card)
        } else {
            if let index = ds.index(where: {
                $0.uuid == card.uuid
            }) {
                ds[index] = card
            }
        }
        if saveToRealm {
            addToRealm(card: card)
        }
    }
    private func addToRealm(card: CardModel) {
        let model: RealmCardPripheral
        if let anItem = realm.object(ofType: RealmCardPripheral.self, forPrimaryKey: card.uuid) {
            model = anItem
        } else {
            model = RealmCardPripheral()
        }

        try! realm.write {
            model.cardName = card.name
            if model.uuid == "" && model.MACAddress == "" {
                model.uuid = card.uuid
                model.MACAddress = card.MACAddress
                model.batteryLevel = card.batteryLevel
                model.firmwareRevisionString = card.firmwareRevisionString
                model.connectionParameters = card.connectionParameters
                model.fsmParameters = card.fsmParameters
            }
            print("Card \(card.uuid) ; Model \(model)")
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
    func stopScanning() {
        bleKit.stopScanning()
    }
    func getLatestAddedCard() -> CardModel? {
        return ds.last
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
        bleKit.tryReconnect(to: uuids, realmPeripheral: peripherals)
    }
    func disconnect(at indexPath: IndexPath) {
        if indexPath.row > self.ds.count {
            return
        }
        self.deleteFromRealm(card: ds[indexPath.row])
        bleKit.decommission(for: self.ds[indexPath.row])
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
