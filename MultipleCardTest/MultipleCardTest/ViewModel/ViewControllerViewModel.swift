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

class DashboardViewModel {
    
    private let bleKit = MFRxBluetoothKitService.shared
    
    private let disposeBag = DisposeBag()

    private var ds: [Monitor] = []
    
    var scanningError: Observable<Result<Bool, Error>> {
        return scanningSubject.asObservable()
    }
    var dataUpdatedObserver: Observable<Result<[Monitor], Error>> {
        return dataUpdatedPublisher.asObservable()
    }
    var disconnectObserver: Observable<Result<Peripheral, Error>> {
        return disconnectPublisher.asObservable()
    }
    var reconnectionObserver: Observable<Result<Monitor, Error>> {
        return reconnectionPublisher.asObservable()
    }
    var readingCardObserver: Observable<Result<Bool, Error>> {
        return readingCardPublisher.asObservable()
    }
    var connectionToCardObserver: Observable<Result<Monitor, Error>> {
        return connectionToCardPublisher.asObservable()
    }
    var commissionObserver: Observable<Result<Bool, Error>>  {
        return commissionPublisher.asObservable()
    }
    var unlinkCardObserver: Observable<Result<Bool, Error>> {
        return unlinkCardSubject.asObservable()
    }
    var startCardBindingObserver: Observable<Result<Bool, Error>> {
        return startCardBindingSubject.asObservable()
    }
    var reConnectingInProgressObserver: Observable<Result<Bool, Error>> {
        return reConnectingInProgressSubject.asObservable()
    }
    
    private var dataUpdatedPublisher = PublishSubject<Result<[Monitor], Error>>()
    private var disconnectPublisher = PublishSubject<Result<Peripheral, Error>>()
    private var reconnectionPublisher = PublishSubject<Result<Monitor, Error>>()
    private var readingCardPublisher = PublishSubject<Result<Bool, Error>>()
    private var connectionToCardPublisher = PublishSubject<Result<Monitor, Error>>()
    private var commissionPublisher = PublishSubject<Result<Bool, Error>>()
    private var unlinkCardSubject = PublishSubject<Result<Bool, Error>> ()
    private var startCardBindingSubject = PublishSubject<Result<Bool, Error>>()
    private var reConnectingInProgressSubject = PublishSubject<Result<Bool, Error>>()
    private var scanningSubject = PublishSubject<Result<Bool, Error>>()
    
    private var connectionDisposables: [Disposable] = []
    func bind() {
        
        bleKit.scanningOutput.subscribe { (result) in
            if let element = result.element {
                switch element {
                case .success(_):
                    break
                case .error(let error):
                    self.scanningSubject.onNext(Result.error(error))
                }
            }
        }.disposed(by: disposeBag)
        
        bleKit.observeMangerStatus()
            .filter {
                $0 == .poweredOn
            }.subscribeOn(MainScheduler.instance)
            .subscribe { (_) in
                self.reconnect()
            }.disposed(by: disposeBag)
        
        bleKit.startCardBindingObserver.subscribe(onNext: { (result) in
            self.startCardBindingSubject.onNext(result)
        }, onError: { (error) in
            self.startCardBindingSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        bleKit.cardBindingObserver.subscribe(onNext: { (result) in
            switch result {
            case .success(let monitor):
                self.add(monitor)
            case .error(let error):
                self.dataUpdatedPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            self.dataUpdatedPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.disconnectionReasonOutput.subscribe(onNext: { (result) in
            switch result {
            case .success(let peripheral):
                self.disconnectPublisher.onNext(Result.success(peripheral.0))
            case .error(let error):
                self.disconnectPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            self.disconnectPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.reConnectingInProgressObserver.subscribe(onNext: { (result) in
            self.reConnectingInProgressSubject.onNext(result)
        }, onError: { (error) in
            self.reConnectingInProgressSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.reConnectionOutput.subscribe(onNext: { (result) in
            switch result {
            case .success(let monitor):
                self.add(monitor)
                self.reconnectionPublisher.onNext(Result.success(monitor))
            case .error(let error):
                self.reconnectionPublisher.onNext(Result.error(error))
            }
        }, onError: { (error) in
            self.reconnectionPublisher.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
        bleKit.unlinkingObserver.subscribe(onNext: { (result) in
            self.unlinkCardSubject.onNext(result)
        }, onError: { (error) in
            self.unlinkCardSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
    }

    private func add(_ monitor: Monitor, saveToRealm: Bool = true) {
        dataUpdatedPublisher.onNext(Result.success(ds))
        if !ds.contains(where: {
            $0.realmCard.uuid == monitor.realmCard.uuid
        }) {
            ds.append(monitor)
        } else {
            if let index = ds.index(where: {
                $0.realmCard.uuid == monitor.realmCard.uuid
            }) {
                ds[index] = monitor
            }
        }
        if saveToRealm {
            RealmManager.shared.addOrUpdate(monitor: monitor)
        }
    }

    func startScanning() {
        bleKit.stopScanning()
        bleKit.startScanning()
    }
    func stopScanning() {
        bleKit.stopScanning()
    }
    func getLatestAddedCard() -> Monitor? {
        return ds.last
    }
    private func reconnect() {
        guard let peripherals = RealmManager.shared.fetchAllMonitors() else {
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
            AppDelegate.shared.log.debug("Fetched \(uuid)")
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
        RealmManager.shared.deleteFromRealm(monitor: ds[indexPath.row])
        bleKit.decommission(for: self.ds[indexPath.row])
        ds.remove(at: indexPath.row)
    }
    func numberOfItems() -> Int {
        return ds.count
    }
    func item(at indexPath: IndexPath) -> Monitor? {
        if indexPath.row < ds.count {
            return ds[indexPath.row]
        }
        return nil 
    }
//    func realmObject(for monitor: Monitor) -> RealmCardPripheral? {
//        return RealmManager.shared.getRealmObject(for: card)
//    }
}
