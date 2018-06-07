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
  var turnOffCardObserver: Observable<Result<Bool, Error>> {
    return turnOffCardSubject.asObservable()
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
  private var turnOffCardSubject = PublishSubject<Result<Bool, Error>>()
  
  private var connectionDisposables: [Disposable] = []
  private let bleKit = MFRxBluetoothKitService.shared
  private let disposeBag = DisposeBag()
  private var ds: [Monitor] = []
  
  func bind() {
    
    bleKit.scanningOutput.subscribe { [weak self] (result) in
      if let element = result.element {
        switch element {
        case .success(_):
          break
        case .error(let error):
          self?.scanningSubject.onNext(Result.error(error))
        }
      }
      }.disposed(by: disposeBag)
    
    bleKit.observeMangerStatus()
      .filter {
        $0 == .poweredOn
      }.subscribeOn(MainScheduler.instance)
      .subscribe { [weak self] (_) in
        self?.reconnect()
      }.disposed(by: disposeBag)
    
    bleKit.startCardBindingObserver.subscribe(onNext: { [weak self] (result) in
      self?.startCardBindingSubject.onNext(result)
    }, onError: { [weak self] (error) in
      self?.startCardBindingSubject.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    bleKit.cardBindingObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let monitor):
        self?.add(monitor)
        self?.bleKit.observeDisconnect(for: monitor.peripheral)
        self?.startCardBindingSubject.onCompleted()
      case .error(let error):
        self?.dataUpdatedPublisher.onNext(Result.error(error))
        self?.startCardBindingSubject.onCompleted()
      }
    }, onError: { [weak self] (error) in
      self?.dataUpdatedPublisher.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    
    bleKit.disconnectionReasonOutput.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let peripheral):
        self?.disconnectPublisher.onNext(Result.success(peripheral))
      case .error(let error):
        self?.disconnectPublisher.onNext(Result.error(error))
      }
    }, onError: { [weak self] (error) in
      self?.disconnectPublisher.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    
    bleKit.reConnectingInProgressObserver.subscribe(onNext: { [weak self] (result) in
      self?.reConnectingInProgressSubject.onNext(result)
    }, onError: { [weak self] (error) in
      self?.reConnectingInProgressSubject.onNext(Result.error(error))
    }, onCompleted: {
        self.reConnectingInProgressSubject.onCompleted()
    }).disposed(by: disposeBag)
    
    bleKit.reConnectionOutput.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let monitor):
        self?.add(monitor)
        self?.reconnectionPublisher.onNext(Result.success(monitor))
      case .error(let error):
        self?.reconnectionPublisher.onNext(Result.error(error))
      }
    }, onError: { [weak self] (error) in
      self?.reconnectionPublisher.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    
    bleKit.unlinkingObserver.subscribe(onNext: { [weak self] (result) in
      self?.unlinkCardSubject.onNext(result)
    }, onError: { [weak self] (error) in
      self?.unlinkCardSubject.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    
    bleKit.turnOffCardObserver.subscribe(onNext: { [weak self] (result) in
      self?.turnOffCardSubject.onNext(result)
    }, onError: { [weak self] (error) in
      self?.turnOffCardSubject.onNext(Result.error(error))
    }).disposed(by: disposeBag)
    
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
  
  func disconnect(at indexPath: IndexPath) {
    if indexPath.row > ds.count {
      AppDelegate.shared.log.error("Index out of bound")
      return
    }
    RealmManager.shared.deleteFromRealm(monitor: ds[indexPath.row])
    bleKit.decommission(for: ds[indexPath.row])
    ds.remove(at: indexPath.row)
  }
  
  func turnOff(at indexPath: IndexPath) {
    if indexPath.row > ds.count {
      AppDelegate.shared.log.error("Index out of bound")
      return
    }
    RealmManager.shared.deleteFromRealm(monitor: ds[indexPath.row])
    bleKit.trunOff(ds[indexPath.row])
    ds.remove(at: indexPath.row)
  }
  
  func numberOfItems() -> Int {
    return ds.count
  }
  
  func item(at indexPath: IndexPath) -> Monitor? {
    if indexPath.row < ds.count {
      let monitor =  ds[indexPath.row]
      if let object = RealmManager.shared.getRealmObject(for: monitor) {
        return (object, monitor.peripheral)
      }
      AppDelegate.shared.log.error("Realm Object not found")
      return nil
    }
    AppDelegate.shared.log.error("Index out of bound")
    return nil
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
  
}
