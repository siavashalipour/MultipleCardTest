//
//  RxBluetoothKitService.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift
import RxCocoa
import CoreBluetooth
import RealmSwift

final class MFRxBluetoothKitService {
  
  static let shared: MFRxBluetoothKitService = MFRxBluetoothKitService.init()
  
  private lazy var batteryFirmwareZip = Observable.zip(batteryObserver, firmwareVersionObserver) {
    return (batteryLevel: $0, firmware: $1)
  }
  typealias Disconnection = (Peripheral, DisconnectionReason?)
  // MARK: - Public outputs
  var scanningOutput: Observable<Result<ScannedPeripheral, Error>> {
    return scanningSubject.share(replay: 1, scope: .forever).asObservable()
  }
  var disconnectionReasonOutput: Observable<Result<Peripheral, Error>> {
    return disconnectionSubject.asObservable()
  }
  var reConnectionOutput: Observable<Result<Monitor, Error>> {
    return reConnectionSubject.asObservable()
  }
  var batteryObserver: Observable<Result<String, Error>> {
    return batterySubject.asObservable().share()
  }
  var macAddressObserver: Observable<Result<String, Error>> {
    return macAddressSubject.asObservable()
  }
  var fsmParamsObserver: Observable<Result<String, Error>> {
    return fsmParamsSubject.asObservable()
  }
  var firmwareVersionObserver: Observable<Result<String, Error>> {
    return firmwareVersionSubject.asObservable().share()
  }
  var connectionParamsObserver: Observable<Result<String, Error>> {
    return connectionParamsSubject.asObservable()
  }
  var setBatteryNotificationObserver: Observable<Result<Bool, Error>> {
    return setBatteryNotificationSubject.asObservable()
  }
  var cardBindingObserver: Observable<Result<Monitor, Error>> {
    return cardBindingSubject.asObservable()
  }
  var turnOffCardObserver: Observable<Result<Bool, Error>> {
    return turnOffCardSubject.asObservable()
  }
  var unlinkingObserver: Observable<Result<Bool, Error>> {
    return unlinkingSubject.asObservable()
  }
  var startCardBindingObserver: Observable<Result<Bool, Error>> {
    return startCardBindingSubject.asObservable()
  }
  var reConnectingInProgressObserver: Observable<Result<Bool, Error>> {
    return reConnectingInProgressSubject.asObservable()
  }
  var debugObserver: Observable<Result<String, Error>> {
    return debugPublisher.asObservable()
  }
  // MARK: - Private fields
  private let debugPublisher = PublishSubject<Result<String, Error>>()
  private let scanningSubject = PublishSubject<Result<ScannedPeripheral, Error>>()
  private let disconnectionSubject = PublishSubject<Result<Peripheral, Error>>()
  private let reConnectionSubject = PublishSubject<Result<Monitor, Error>>()
  private let cardBindingSubject = PublishSubject<Result<Monitor, Error>>()
  private let batterySubject = PublishSubject<Result<String, Error>>()
  private let macAddressSubject = PublishSubject<Result<String, Error>>()
  private let fsmParamsSubject = PublishSubject<Result<String, Error>>()
  private let firmwareVersionSubject = PublishSubject<Result<String, Error>>()
  private let connectionParamsSubject = PublishSubject<Result<String, Error>>()
  private let setBatteryNotificationSubject = PublishSubject<Result<Bool, Error>>()
  private let turnOffCardSubject = PublishSubject<Result<Bool, Error>>()
  private let unlinkingSubject = PublishSubject<Result<Bool, Error>>()
  private let discoveredCharacteristicsSubject = PublishSubject<Result<[Characteristic], Error>>()
  private let startCardBindingSubject = PublishSubject<Result<Bool, Error>>()
  private let reConnectingInProgressSubject = PublishSubject<Result<Bool, Error>>()
  private let centralManager = CentralManager(queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "some.very.unique.key" as AnyObject])
  private let scheduler: ConcurrentDispatchQueueScheduler
  private let disposeBag = DisposeBag()
  private var peripheralConnections: [Peripheral: Disposable] = [:]
  private var scanningDisposable: Disposable?
  private var foundSafedome: Bool = false {
    didSet {
      if foundSafedome {
        stopScanning()
      }
    }
  }
  // MARK:- Constants
  private let kRSSIThreshold: Double = -60
  private let kReadingTimeout: Double = 40
  
  // MARK: - Initialization
  private init() {
    let timerQueue = DispatchQueue(label: Constant.Strings.defaultDispatchQueueLabel)
    scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
  }
  // MARK: - Scanning for peripherals
  
  // You start from observing state of your CentralManager object. Within RxBluetoothKit v.5.0, it is crucial
  // that you use .startWith(:_) operator, and pass the initial state of your CentralManager with
  // centralManager.state.
  func startScanning() {
    if let scanningDisposable = scanningDisposable {
      scanningDisposable.dispose()
    }
    scanningDisposable = centralManager.observeState()
      .startWith(centralManager.state)
      .filter {
        $0 == .poweredOn
      }
      .timeout(120, scheduler: MainScheduler.instance)
      .subscribeOn(MainScheduler.instance)
      .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
        guard let `self` = self else {
          return Observable.empty()
        }
        return self.centralManager.scanForPeripherals(withServices: nil)
      }
      .subscribe(onNext: { [weak self] scannedPeripheral in
        let canConnect = scannedPeripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scannedPeripheral.rssi.doubleValue > (self?.kRSSIThreshold)!
        AppDelegate.shared.log.debug("Scanned and find \(scannedPeripheral.peripheral.name ?? "") - \(scannedPeripheral.rssi.doubleValue)")
        if canConnect {
          scannedPeripheral.peripheral.establishConnection()
            .subscribe(onNext: { (_) in
              let card = RealmCardPripheral()
              card.update(for: scannedPeripheral.peripheral)
              let monitor = (card, scannedPeripheral.peripheral)
              self?.startCardBinding(for: monitor)
            }, onError: { (error) in
              self?.disconnectionSubject.onNext(Result.error(error))
            }).disposed(by: (self?.disposeBag)!)
          self?.foundSafedome = true
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Scan failed \(error)")
          self?.scanningSubject.onNext(Result.error(error))
      })
  }
  
  func observeMangerStatus() -> Observable<BluetoothState> {
    return centralManager.observeState().startWith(centralManager.state)
  }
  
  func tryReconnect(to peripherals: [UUID]) {
    let peripheralsToReConnect = centralManager.retrievePeripherals(withIdentifiers: peripherals)
    if peripheralsToReConnect.count < 1 {
      reConnectionSubject.onNext(Result.error(BluetoothServicesError.peripheralNil))
    }
    reconnectCardLinking(peripherals: peripheralsToReConnect)
    
  }
  
  func stopScanning() {
    guard let scanningDisposable = scanningDisposable else { return }
    scanningDisposable.dispose()
  }
  private func startScanningAndReconnect() {
    guard let fetched = RealmManager.shared.fetchAllMonitors() else {
      return
    }
    if fetched.count < 1 {
      return
    }
    if let scanningDisposable = scanningDisposable {
      scanningDisposable.dispose()
    }
    
    scanningDisposable = centralManager.observeState()
      .startWith(centralManager.state)
      .filter {
        $0 == .poweredOn
      }
      .subscribeOn(MainScheduler.instance)
      .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
        guard let `self` = self else {
          return Observable.empty()
        }
        return self.centralManager.scanForPeripherals(withServices: nil)
      }.takeWhile({ _ in
        fetched.count > 0
      })
      .subscribe(onNext: { [weak self] scannedPeripheral in
        let canConnect = scannedPeripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scannedPeripheral.rssi.doubleValue > (self?.kRSSIThreshold)!
        AppDelegate.shared.log.debug("Reconnect Scanned and find \(scannedPeripheral.peripheral.name ?? "") - \(scannedPeripheral.rssi.doubleValue)")
        if canConnect && RealmManager.shared.getRealmObject(for: scannedPeripheral.peripheral) != nil {
          self?.tryReconnect(to: [scannedPeripheral.peripheral.identifier])
          self?.foundSafedome = true
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Scan failed \(error)")
          self?.scanningSubject.onNext(Result.error(error))
      })
  }
  // Disposal of a given connection disposable disconnects automatically from a peripheral
  // So firstly, you discconect from a perpiheral and then you remove of disconnected Peripheral
  // from the Peripheral's collection.
  func disconnect(_ peripheral: Peripheral) {
    centralManager.centralManager.cancelPeripheralConnection(peripheral.peripheral)
    self.startScanningAndReconnect()
    self.disconnectionSubject.onNext(Result.success(peripheral))
    guard let disposable = peripheralConnections[peripheral] else {
      return
    }
    disposable.dispose()
    peripheralConnections[peripheral] = nil
  }
  
  func establishConnectionAndAddToConnectionDisposal(for peripheral: Peripheral) {
    if RealmManager.shared.getRealmObject(for: peripheral) != nil {
      let disposable = peripheral.establishConnection().subscribe()
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  // MARK: - Discovering Characteristics
  func discoverCharacteristics(for service: Service) {
    service.discoverCharacteristics(nil).subscribe(onSuccess: { [unowned self] characteristics in
      self.discoveredCharacteristicsSubject.onNext(Result.success(characteristics))
      }, onError: { error in
        self.discoveredCharacteristicsSubject.onNext(Result.error(error))
    }).disposed(by: disposeBag)
  }
  
  // MARK: - Private methods
  private func reconnectCardLinking(peripherals: [Peripheral]) {
    var copyPeripherals = peripherals
    if copyPeripherals.count == 0 {
      reConnectingInProgressSubject.onCompleted()
      return
    }
    // notify the observer that reconnection process is about to start
    reConnectingInProgressSubject.onNext(Result.success(true))
    let peripheral = copyPeripherals.removeFirst()
    let disposable = peripheral.establishConnection().subscribe({ [unowned self] (event) in
      if let peripheral = event.element {
        AppDelegate.shared.log.debug("peripheral \(peripheral.identifier) status \(peripheral.isConnected)")
        if peripheral.isConnected {
          if let card = RealmManager.shared.getRealmObject(for: peripheral) {
            RealmManager.shared.beginWrite()
            card.isConnected = true
            card.isOn = true
            RealmManager.shared.commitWrite()
            MFFirmwareUpdateManager.shared.startChecking(for: (card, peripheral))
            self.reconnectOrTurnOnMonitor((card, peripheral)).subscribe(onNext: { (result) in
              self.reConnectionSubject.onNext(result)
              self.reconnectCardLinking(peripherals: copyPeripherals)
            }, onError: { (error) in
              
            }).disposed(by: self.disposeBag)
          }
        }
      }
    })
    if peripheral.isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  // When you observe disconnection from a peripheral, you want to be sure that you take an action on both .next and
  // .error events. For instance, when your device enters BluetoothState.poweredOff, you will receive an .error event.
  func observeDisconnect(for peripheral: Peripheral) {
    centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
      self.disconnect(peripheral)
      }, onError: { [unowned self] error in
        self.disconnectionSubject.onNext(Result.error(error))
    }).disposed(by: disposeBag)
  }
}
// MARK:- Readings
extension MFRxBluetoothKitService {
  
  private func readDiagnosticFSMMatches(for monitor: Monitor) -> Observable<Result<Bool,Error>> {
    return Observable.create({ [weak self] (observer) -> Disposable in
      let peripheral = monitor.peripheral
      let isConnected = peripheral.isConnected
      
      let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.fsmParameters).asObservable() }
      let connectObservableCreator = {
        return peripheral.establishConnection()
          .do(onNext: { [weak self] _ in
            self?.observeDisconnect(for: peripheral)
          })
          .flatMap { $0.readValue(for: DeviceCharacteristic.fsmParameters) }
      }
      let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
      let disposable = observable.timeout(self!.kReadingTimeout, scheduler: MainScheduler.asyncInstance)
        .subscribe(onNext: { char in
          if let value = char.value {
            let nsData = NSData.init(data: value)
            var fsmParams: MFSFSMParameters = MFSFSMParameters()
            nsData.getBytes(&fsmParams, length: Int(Constant.PackageSizes.kSizeofMFSFSMParameters))
            let hexStr = char.characteristic.value?.hexadecimalString ?? ""
            observer.onNext(Result.success(fsmParams == CardParameters.kDefaultFSMParameters || hexStr == CardParameters.kCommissionedFSMHexStr))
          }
          AppDelegate.shared.log.debug("Diagnostic read \(char.characteristic.value?.hexadecimalString ?? "")")
          }, onError: { error in
            AppDelegate.shared.log.error("Diagnostic read \(error)")
            observer.onNext(Result.error(error))
        })
      
      if isConnected {
        self?.disposeBag.insert(disposable)
        self?.peripheralConnections[peripheral] = disposable
      }
      
      return Disposables.create()
    })
    
  }
  
  private func readMACAddress(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.MACAddress).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.readValue(for: DeviceCharacteristic.MACAddress) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable.timeout(kReadingTimeout, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] char in
        if let value = char.characteristic.value {
          let str = value.hexadecimalString
          var macAddress = ""
          var i = 0
          for char in str {
            if i != 0 && i % 2 == 0 {
              macAddress.append(":")
            }
            macAddress.append(char)
            i += 1
          }
          self?.macAddressSubject.onNext(Result.success(macAddress))
        }
        AppDelegate.shared.log.debug("MACAddress read \(char.characteristic.value?.hexadecimalString ?? "")")
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("MACAddress read \(error)")
          self?.macAddressSubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  
  private func readBattery(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.batteryLevel).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.readValue(for: DeviceCharacteristic.batteryLevel) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable.timeout(kReadingTimeout, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] char in
        if let value = char.characteristic.value {
          self?.batterySubject.onNext(Result.success("\(value[0])"))
          AppDelegate.shared.log.debug("Read Battery \(value[0])")
          self?.debugPublisher.onNext(Result.success("Read Battery \(value[0])"))
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Read Battery: \(error)")
          self?.debugPublisher.onNext(Result.success("Read Battery: \(error)"))
          self?.batterySubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  
  private func setBatteryNotificationOn(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.observeValueUpdateAndSetNotification(for: DeviceCharacteristic.batteryLevel).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.observeValueUpdateAndSetNotification(for: DeviceCharacteristic.batteryLevel) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable
      .subscribe(onNext: { [weak self] char in
        AppDelegate.shared.log.debug("Set battery notification Success")
        self?.setBatteryNotificationSubject.onNext(Result.success(true))
        }, onError: { [weak self] error in
          self?.setBatteryNotificationSubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  
  private func readFirmwareVersion(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.firmwareRevisionString).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.readValue(for: DeviceCharacteristic.firmwareRevisionString) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable.timeout(kReadingTimeout, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] char in
        if let value = char.characteristic.value {
          let firmware = String.init(data: value, encoding: String.Encoding.utf8)
          self?.firmwareVersionSubject.onNext(Result.success(firmware ?? "wrong encoding"))
          AppDelegate.shared.log.debug("Read Firmware: \(firmware ?? "wrong encoding")")
          self?.debugPublisher.onNext(Result.success("Read Firmware: \(firmware ?? "wrong encoding")"))
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Read Firmware: \(error)")
          self?.debugPublisher.onNext(Result.success("Read Firmware: \(error)"))
          self?.firmwareVersionSubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  
  private func readFSMParameters(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.fsmParameters).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.readValue(for: DeviceCharacteristic.fsmParameters) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable.timeout(kReadingTimeout, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] char in
        if let value = char.characteristic.value {
          let str = value.hexadecimalString
          self?.fsmParamsSubject.onNext(Result.success(str))
          AppDelegate.shared.log.debug("Read FSM: \(str)")
          self?.debugPublisher.onNext(Result.success("Read FSM: \(str)"))
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Read FSM: \(error)")
          self?.debugPublisher.onNext(Result.success("Read FSM: \(error)"))
          self?.fsmParamsSubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
  
  private func readConnectionParameters(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    let isConnected = peripheral.isConnected
    
    let connectedObservableCreator = { return peripheral.readValue(for: DeviceCharacteristic.connectionParameters).asObservable() }
    let connectObservableCreator = {
      return peripheral.establishConnection()
        .do(onNext: { [weak self] _ in
          self?.observeDisconnect(for: peripheral)
        })
        .flatMap { $0.readValue(for: DeviceCharacteristic.connectionParameters) }
    }
    let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
    let disposable = observable.timeout(kReadingTimeout, scheduler: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] char in
        if let value = char.characteristic.value {
          let str = value.hexadecimalString
          self?.connectionParamsSubject.onNext(Result.success(str))
          AppDelegate.shared.log.debug("Read Connection Params: \(str)")
          self?.debugPublisher.onNext(Result.success("Read Connection Params: \(str)"))
        }
        }, onError: { [weak self] error in
          AppDelegate.shared.log.error("Read Connection Params: \(error)")
          self?.debugPublisher.onNext(Result.success("Read Connection Params: \(error)"))
          self?.connectionParamsSubject.onNext(Result.error(error))
      })
    
    if isConnected {
      disposeBag.insert(disposable)
      peripheralConnections[peripheral] = disposable
    }
  }
}
// MARK:- Writings
extension MFRxBluetoothKitService {
  private func writeDefaultConnectionParameters(for monitor: Monitor) -> Observable<Result<String, Error>> {
    return Observable.create { (observer) -> Disposable in
      let peripheral = monitor.peripheral
      var a = CardParameters.kDefaultConnectionParameters
      let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters))
      peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
        let str = char.characteristic.value?.hexadecimalString
        observer.onNext(Result.success(str ?? ""))
        AppDelegate.shared.log.debug("write Default Connection Parameters success \(str ?? "")")
        self.debugPublisher.onNext(Result.success("write Default Connection Parameters success"))
      }) { (error) in
        AppDelegate.shared.log.error("write Default Connection Parameters \(error)")
        self.debugPublisher.onNext(Result.success("write Default Connection Parameters error"))
        observer.onNext(Result.error(error))
        }.disposed(by: self.disposeBag)
      
      return Disposables.create()
    }
    
  }
  private func writeFSMParameters(for monitor: Monitor) -> Observable<Result<String, Error>> {
    return Observable.create({ (observer) -> Disposable in
      let peripheral = monitor.peripheral
      var a = CardParameters.kDefaultFSMParameters
      let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSFSMParameters))
      peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
        let str = char.characteristic.value?.hexadecimalString
        observer.onNext(Result.success(str ?? ""))
        AppDelegate.shared.log.debug("Write FSM success: \(str ?? "")")
        RealmManager.shared.beginWrite()
        monitor.realmCard.fsmParameters = str ?? ""
        RealmManager.shared.commitWrite()
        self.debugPublisher.onNext(Result.success("Write FSM success"))
      }) { (error) in
        AppDelegate.shared.log.error("Write FSM: \(error)")
        self.debugPublisher.onNext(Result.success("Write FSM error"))
        observer.onNext(Result.error(error))
        }.disposed(by: self.disposeBag)
      
      return Disposables.create()
    })
    
  }
  private func writeFindMonitorParameters(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    var a = CardParameters.kMFSFindMonitorParameters
    let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSFindMonitorParameters))
    peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.findMonitorParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
      AppDelegate.shared.log.debug("write Find Monitor success: \(String(describing: char.characteristic.value?.hexadecimalString))")
    }) { (error) in
      AppDelegate.shared.log.error("write Find Monitor: \(error)")
      }.disposed(by: disposeBag)
  }
}

// MARK:- Card Flows
extension MFRxBluetoothKitService {
  private func startCardBinding(for monitor: Monitor) {
    readBattery(for: monitor)
    readFirmwareVersion(for: monitor)
    startCardBindingSubject.onNext(Result.success(true))
    //Write the Connection parameters
    let monitorCopy = monitor

    
    self.writeDefaultConnectionParameters(for: monitor).subscribe(onNext: { (result) in
      switch result {
      case .success(let connection):
        monitorCopy.realmCard.connectionParameters = connection
        self.writeFSMParameters(for: monitor)
          .subscribe(onNext: { (result) in
            switch result {
            case .success(let fsm):
              monitorCopy.realmCard.fsmParameters = fsm
              monitor.realmCard.isOn = true
              RealmManager.shared.commitWrite()
              MFFirmwareUpdateManager.shared.startChecking(for: monitorCopy)
              AppDelegate.shared.log.debug("Card binding Done!")
              self.debugPublisher.onNext(Result.success("Card binding Done"))
              self.cardBindingSubject.onNext(Result.success(monitorCopy))
            case .error(let error):
              self.cardBindingSubject.onNext(Result.error(error))
            }
          }, onError: { (error) in
            self.cardBindingSubject.onNext(Result.error(error))
          }).disposed(by: (self.disposeBag))
      case .error(let error):
        self.cardBindingSubject.onNext(Result.error(error))
        break
      }
    }, onError: { [weak self] (error) in
      self?.cardBindingSubject.onNext(Result.error(error))
    }).disposed(by: (self.disposeBag))
    
    batteryFirmwareZip.subscribe(onNext: { [weak self] (batteryLevel, firmware) in
      switch batteryLevel {
      case .success(let battery):
        RealmManager.shared.beginWrite()
        monitorCopy.realmCard.batteryLevel = battery
      case .error(let error):
        self?.cardBindingSubject.onNext(Result.error(error))
        break
      }
      switch firmware {
      case .success(let firmware):
        monitorCopy.realmCard.firmwareRevisionString = firmware
      case .error(let error):
        self?.cardBindingSubject.onNext(Result.error(error))
        break
      }
      }, onError: { [weak self] (error) in
        self?.cardBindingSubject.onNext(Result.error(error))
    }).disposed(by: self.disposeBag)
  }
  
  func reconnectOrTurnOnMonitor(_ monitor: Monitor) -> Observable<Result<Monitor, Error>> {
    observeDisconnect(for: monitor.peripheral)
    return Observable.create { (observer) -> Disposable in
      self.readBattery(for: monitor)
      self.readFirmwareVersion(for: monitor)
      // read diagnostic FSM
      self.readDiagnosticFSMMatches(for: monitor).subscribe(onNext: { (result) in
        switch result {
        case .success(let isMatch):
          if !isMatch {
            AppDelegate.shared.log.debug("Diagnostic read doesn't match => writing fsm again")
            self.debugPublisher.onNext(Result.success("Diagnostic read doesn't match => writing fsm again"))
            self.writeFSMParameters(for: monitor).subscribe().disposed(by: self.disposeBag)
          } else {
            AppDelegate.shared.log.debug("Diagnostic matches => continue reconnecting")
            self.debugPublisher.onNext(Result.success("Diagnostic matches => continue reconnecting"))
          }
        case .error(let error):
          AppDelegate.shared.log.error("Recconnect Read Diagnostic \(error)")
          self.debugPublisher.onNext(Result.success("Recconnect Read Diagnostic \(error) - Diagnostic read error => writing fsm again"))
          AppDelegate.shared.log.error("Diagnostic read error => writing fsm again")
          self.debugPublisher.onNext(Result.success("Diagnostic read error => writing fsm again"))
          self.writeFSMParameters(for: monitor).subscribe().disposed(by: self.disposeBag)
        }
      }, onError: { (error) in
        AppDelegate.shared.log.error("Recconnect Read Diagnostic \(error)")
        self.debugPublisher.onNext(Result.success("Recconnect Read Diagnostic \(error)"))
        observer.onNext(Result.error(error))
      }).disposed(by: self.disposeBag)
      // write connection params
      let defaultWriteObserver = self.writeDefaultConnectionParameters(for: monitor)
      let zip = Observable.zip(self.batteryObserver, self.firmwareVersionObserver, defaultWriteObserver) {
        return (batteryLevel: $0, firmware: $1, connection: $2)
      }
      let monitorCopy = monitor
      zip.subscribe(onNext: { (batteryLevel, firmware, connection) in
        RealmManager.shared.beginWrite()
        switch batteryLevel {
        case .success(let battery):
          monitorCopy.realmCard.batteryLevel = battery
        case .error(let error):
          observer.onNext(Result.error(error))
          break
        }
        switch firmware {
        case .success(let firmware):
          monitorCopy.realmCard.firmwareRevisionString = firmware
        case .error(let error):
          observer.onNext(Result.error(error))
          break
        }
        switch connection {
        case .success(let connection):
          monitorCopy.realmCard.connectionParameters = connection
        case .error(let error):
          observer.onNext(Result.error(error))
          break
        }
        RealmManager.shared.commitWrite()
        observer.onNext(Result.success(monitorCopy))
      }, onError: { (error) in
        observer.onNext(Result.error(error))
      }).disposed(by: self.disposeBag)
      
      return Disposables.create()
    }
  }
  
  func decommission(for monitor: Monitor) {
    unlink(monitor)
  }
  
  func turnOnLED(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    var a: UInt8 = UInt8(1)
    let data = NSData.init(bytes: &a, length: MemoryLayout.size(ofValue: a))
    peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
      AppDelegate.shared.log.debug("turn on LED success: \(String(describing: char.characteristic.value?.hexadecimalString))")
    }) { (error) in
      AppDelegate.shared.log.error("turn on LED: \(error)")
      }.disposed(by: disposeBag)
  }
  
  func turnOffLED(for monitor: Monitor) {
    let peripheral = monitor.peripheral
    var a: UInt8 = UInt8(0)
    let data = NSData.init(bytes: &a, length: MemoryLayout.size(ofValue: a))
    peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
      AppDelegate.shared.log.debug("Turn off LED Success: \(String(describing: char.characteristic.value?.hexadecimalString))")
    }) { (error) in
      AppDelegate.shared.log.error("Turn Off LED: \(error)")
      }.disposed(by: disposeBag)
  }
  
  func trunOff(_ monitor: Monitor) {
    let peripheral = monitor.peripheral
    var a: UInt8 = 1
    let data = NSData.init(bytes: &a, length: MemoryLayout.size(ofValue: a))
    
    peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.cardOff, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { [weak self] (char) in
      AppDelegate.shared.log.debug("turn off card success: \(String(describing: char.characteristic.value?.hexadecimalString))")
      self?.turnOffCardSubject.onNext(Result.success(true))
      self?.observeDisconnect(for: peripheral)
      self?.startScanningAndReconnect()
    }) { [weak self] (error) in
      AppDelegate.shared.log.error("turn off card: \(error)")
      self?.debugPublisher.onNext(Result.success("turn off card: \(error)"))
      self?.turnOffCardSubject.onNext(Result.error(error))
      }.disposed(by: disposeBag)
    
  }
  
  private func doDecommission(for peripheral: Peripheral) {
    peripheralConnections[peripheral]?.disposed(by: disposeBag)
    var a = CardParameters.kDecommissionFSMParameters
    let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSFSMParameters))
    let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { [weak self] (char) in
      AppDelegate.shared.log.debug("decommission success: \(String(describing: char.characteristic.value?.hexadecimalString))")
      self?.debugPublisher.onNext(Result.success("decommission success:"))
      self?.disconnect(peripheral)
      self?.unlinkingSubject.onNext(Result.success(true))
    }) { [weak self] (error) in
      AppDelegate.shared.log.error("decommission: \(error)")
      self?.debugPublisher.onNext(Result.success("decommission: \(error)"))
      self?.unlinkingSubject.onNext(Result.error(error))
    }
    disposeBag.insert(disposable)
  }
  
  private func unlink(_ monitor: Monitor) {
    let peripheral = monitor.peripheral
    doDecommission(for: peripheral)
  }
}
