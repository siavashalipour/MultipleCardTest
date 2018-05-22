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

// RxBluetoothKitService is a class encapsulating logic for most operations you might want to perform
// on a CentralManager object. Here you can see an example usage of such features as scanning for peripherals,
// discovering services and discovering peripherals.

final class RxBluetoothKitService: NSObject {
    
    typealias Disconnection = (Peripheral, DisconnectionReason?)
    private let kRSSIThreshold: Double = -60
    // MARK: - Public outputs
    
    var scanningOutput: Observable<Result<ScannedPeripheral, Error>> {
        return scanningSubject.share(replay: 1, scope: .forever).asObservable()
    }
    
    var discoveredServicesOutput: Observable<Result<[Service], Error>> {
        return discoveredServicesSubject.asObservable()
    }
    
    var discoveredCharacteristicsOutput: Observable<Result<[Characteristic], Error>> {
        return discoveredCharacteristicsSubject.asObservable()
    }
    
    var disconnectionReasonOutput: Observable<Result<Disconnection, Error>> {
        return disconnectionSubject.asObservable()
    }
    
    var readValueOutput: Observable<Result<Characteristic, Error>> {
        return readValueSubject.asObservable()
    }
    
    var writeValueOutput: Observable<Result<Characteristic, Error>> {
        return writeValueSubject.asObservable()
    }
    
    var updatedValueAndNotificationOutput: Observable<Result<Characteristic, Error>> {
        return updatedValueAndNotificationSubject.asObservable()
    }
    
    var reConnectionOutput: Observable<Result<Peripheral, Error>> {
        return reConnectionSubject.asObservable()
    }
    
    var batteryObserver: Observable<Result<String, Error>> {
        return batterySubject.asObservable()
    }
    var macAddressObserver: Observable<Result<String, Error>> {
       return macAddressSubject.asObservable()
    }
    var fsmParamsObserver: Observable<Result<String, Error>> {
        return fsmParamsSubject.asObservable()
    }
    var firmwareVersionObserver: Observable<Result<String, Error>> {
        return firmwareVersionSubject.asObservable()
    }
    var connectionParamsObserver: Observable<Result<String, Error>> {
        return connectionParamsSubject.asObservable()
    }
    
    private let scanningSubject = PublishSubject<Result<ScannedPeripheral, Error>>()
    
    private let discoveredServicesSubject = PublishSubject<Result<[Service], Error>>()
    
    private let disconnectionSubject = PublishSubject<Result<Disconnection, Error>>()
    
    private let readValueSubject = PublishSubject<Result<Characteristic, Error>>()
    
    private let writeValueSubject = PublishSubject<Result<Characteristic, Error>>()
    
    private let updatedValueAndNotificationSubject = PublishSubject<Result<Characteristic, Error>>()
    
    private let reConnectionSubject = PublishSubject<Result<Peripheral, Error>>()
    
    // read
    private let batterySubject = PublishSubject<Result<String, Error>>()
    private let macAddressSubject = PublishSubject<Result<String, Error>>()
    private let fsmParamsSubject = PublishSubject<Result<String, Error>>()
    private let firmwareVersionSubject = PublishSubject<Result<String, Error>>()
    private let connectionParamsSubject = PublishSubject<Result<String, Error>>()
    
    private let discoveredCharacteristicsSubject = PublishSubject<Result<[Characteristic], Error>>()
    // MARK: - Private fields
    
    private let centralManager = CentralManager(queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "some.very.unique.key" as AnyObject])
    
    private let scheduler: ConcurrentDispatchQueueScheduler
    
    private let disposeBag = DisposeBag()
    
    var peripheralConnections: [Peripheral: Disposable] = [:]
    
    private var scanningDisposable: Disposable!
    
    private var connectionDisposable: Disposable!
    
    private var notificationDisposables: [Characteristic: Disposable] = [:]
    
    // MARK: - Initialization
    override init() {
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
            .subscribeOn(MainScheduler.instance)
            //.timeout(30.0, scheduler: scheduler)
            .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                guard let `self` = self else {
                    return Observable.empty()
                }
                return self.centralManager.scanForPeripherals(withServices: nil)
            }
            .subscribe(onNext: { [weak self] scannedPeripheral in
                let canConnect = scannedPeripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scannedPeripheral.rssi.doubleValue > (self?.kRSSIThreshold)!
                    self?.disconnect(scannedPeripheral.peripheral)
                if canConnect {
                    self?.scanningSubject.onNext(Result.success(scannedPeripheral))
                }
                }, onError: { [weak self] error in
                    self?.scanningSubject.onNext(Result.error(error))
            })
    }
    func tryReconnect(to peripherals: [UUID]) {
        let peripheralsToReConnect = self.centralManager.retrievePeripherals(withIdentifiers: peripherals)
        if peripheralsToReConnect.count < 1 {
            reConnectionSubject.onNext(Result.error(BluetoothServicesError.peripheralNil))
        }
        for peripheral in peripheralsToReConnect {
            let disposable = peripheral.establishConnection().subscribe({ (event) in
                if let peripheral = event.element {
                    print(peripheral.isConnected)
                    if peripheral.isConnected {
                        self.reConnectionSubject.onNext(Result.success(peripheral)) // notify before commissioning since this is reconnect and most definitely is commissioned
                        self.writeFSMParameters(for: peripheral).subscribe(onNext: { (success) in
                            if !success {
                                print("reconnect commission error")
                                self.reConnectionSubject.onNext(Result.error(BluetoothServicesError.commissioningError))
                            }
                        }, onError: { (error) in
                            print("reconnect commission error \(error)")
                            self.reConnectionSubject.onNext(Result.error(error))
                        }).disposed(by: self.disposeBag)
                    }
                }
            })
            if peripheral.isConnected {
                disposeBag.insert(disposable)
            } else {
                peripheralConnections[peripheral] = disposable
            }
        }
        
    }
    // If you wish to stop scanning for peripherals, you need to dispose the Disposable object, created when
    // you either subscribe for events from an observable returned by centralManager.scanForPeripherals(:_), or you bind
    // an observer to it. Check starScanning() above for details.
    func stopScanning() {
        guard let scanningDisposable = scanningDisposable else { return }
        scanningDisposable.dispose()
    }
    
    // MARK: - Peripheral Connection & Discovering Services
    
    // When you discover a service, first you need to establish a connection with a peripheral. Then you call
    // discoverServices(:_) for that peripheral object.
    func discoverServices(for peripheral: Peripheral) {
        let isConnected = peripheral.isConnected
        
        let connectedObservableCreator = { return peripheral.discoverServices(nil).asObservable() }
        let connectObservableCreator = {
            return peripheral.establishConnection()
                .do(onNext: { [weak self] _ in
                    self?.observeDisconnect(for: peripheral)
                })
                .flatMap { $0.discoverServices(nil) }
        }
        let observable = isConnected ? connectedObservableCreator(): connectObservableCreator()
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] services in
            self?.discoveredServicesSubject.onNext(Result.success(services))
            for service in services {
                RxBluetoothKitService().discoverCharacteristics(for: service)
            }
            }, onError: { [weak self] error in
                self?.discoveredServicesSubject.onNext(Result.error(error))
        })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
    
    // Disposal of a given connection disposable disconnects automatically from a peripheral
    // So firstly, you discconect from a perpiheral and then you remove of disconnected Peripheral
    // from the Peripheral's collection.
    func disconnect(_ peripheral: Peripheral) {
        guard let disposable = peripheralConnections[peripheral] else {
            return
        }
        disposable.dispose()
        peripheralConnections[peripheral] = nil
        centralManager.centralManager.cancelPeripheralConnection(peripheral.peripheral)
    }

    // MARK: - Discovering Characteristics
    func discoverCharacteristics(for service: Service) {
        service.discoverCharacteristics(nil).subscribe(onSuccess: { [unowned self] characteristics in
            self.discoveredCharacteristicsSubject.onNext(Result.success(characteristics))
            }, onError: { error in
                self.discoveredCharacteristicsSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Reading from and writing to a characteristic
    func readValueFrom(_ characteristic: Characteristic) {
        characteristic.readValue().subscribe(onSuccess: { [unowned self] characteristic in
            self.readValueSubject.onNext(Result.success(characteristic))
            }, onError: { [unowned self] error in
                self.readValueSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }
    
    func writeValueTo(characteristic: Characteristic, data: Data) {
        guard let writeType = characteristic.determineWriteType() else {
            return
        }
        
        characteristic.writeValue(data, type: writeType).subscribe(onSuccess: { [unowned self] characteristic in
            self.writeValueSubject.onNext(Result.success(characteristic))
            }, onError: { [unowned self] error in
                self.writeValueSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Characteristic notifications
    
    // observeValueUpdateAndSetNotification(:_) returns a disposable from subscription, which triggers notifying start
    // on a selected characteristic.
    func observeValueUpdateAndSetNotification(for characteristic: Characteristic) {
        if let _ = notificationDisposables[characteristic] {
            self.updatedValueAndNotificationSubject.onNext(Result.error(RxBluetoothServiceError.redundantStateChange))
        } else {
            let disposable = characteristic.observeValueUpdateAndSetNotification()
                .subscribe(onNext: { [weak self] (characteristic) in
                    self?.updatedValueAndNotificationSubject.onNext(Result.success(characteristic))
                    }, onError: { [weak self] (error) in
                        self?.updatedValueAndNotificationSubject.onNext(Result.error(error))
                })
            
            notificationDisposables[characteristic] = disposable
        }
    }
    
    func disposeNotification(for characteristic: Characteristic) {
        if let disposable = notificationDisposables[characteristic] {
            disposable.dispose()
            notificationDisposables[characteristic] = nil
        } else {
            self.updatedValueAndNotificationSubject.onNext(Result.error(RxBluetoothServiceError.redundantStateChange))
        }
    }
    
    // observeNotifyValue tells us when exactly a characteristic has changed it's state (e.g isNotifying).
    // We need to use this method, because hardware needs an amount of time to switch characteristic's state.
    func observeNotifyValue(peripheral: Peripheral, characteristic: Characteristic) {
        peripheral.observeNotifyValue(for: characteristic)
            .subscribe(onNext: { [unowned self] (characteristic) in
                self.updatedValueAndNotificationSubject.onNext(Result.success(characteristic))
                }, onError: { [unowned self] (error) in
                    self.updatedValueAndNotificationSubject.onNext(Result.error(error))
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Private methods
    
    // When you observe disconnection from a peripheral, you want to be sure that you take an action on both .next and
    // .error events. For instance, when your device enters BluetoothState.poweredOff, you will receive an .error event.
    func observeDisconnect(for peripheral: Peripheral) {
        centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
            self.disconnectionSubject.onNext(Result.success((peripheral, reason)))
            self.disconnect(peripheral)
            }, onError: { [unowned self] error in
                self.disconnectionSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }
}
// MARK:- Readings
extension RxBluetoothKitService {
    
    func readMACAddress(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
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
                print(char.characteristic.value!.hexadecimalString)
                }, onError: { [weak self] error in
                    print("MAC \(error)")
                    self?.macAddressSubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
    func readBattery(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] char in
                if let value = char.characteristic.value {
                    self?.batterySubject.onNext(Result.success("\(value[0])"))
                    print("Bat :\(value[0])")
                }
                }, onError: { [weak self] error in
                    print("bat \(error)")
                    self?.batterySubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
    func readFirmwareVersion(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] char in
                if let value = char.characteristic.value {
                    let firmware = String.init(data: value, encoding: String.Encoding.utf8)
                    self?.firmwareVersionSubject.onNext(Result.success(firmware ?? "wrong encoding"))
                    print("Firm :\(firmware ?? "wrong encoding")")
                }
                }, onError: { [weak self] error in
                    print("Firm \(error)")
                    self?.firmwareVersionSubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
    func readFSMParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] char in
                if let value = char.characteristic.value {
                    let str = value.hexadecimalString
                    self?.fsmParamsSubject.onNext(Result.success(str))
                    print("FSM: \(str)")
                }
                }, onError: { [weak self] error in
                    print("fsm \(error)")
                    self?.fsmParamsSubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
    func readConnectionParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
        let disposable = observable.timeout(40, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] char in
                if let value = char.characteristic.value {
                    let str = value.hexadecimalString
                    self?.connectionParamsSubject.onNext(Result.success(str))
                    print("param \(str)")
                }
                }, onError: { [weak self] error in
                    print("param \(error)")
                    self?.connectionParamsSubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
    }
}
// MARK:- Writings
extension RxBluetoothKitService {
    func writeDefaultConnectionParameters(for card: CardModel) -> Observable<Bool> {
        return Observable.create { (observer) -> Disposable in
            if let peripheral = card.peripheral {
                var a = CardParameters.kDefaultConnectionParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSConnectionParameters))
                peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
                    DispatchQueue.main.async {
                        observer.onNext(true)
                    }
                }) { (error) in
                    print("!!!! error writing \(data) with error: \(error)")
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                    }.disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }

    }
    func writeFSMParameters(for peripheral: Peripheral) -> Observable<Bool> {
        return Observable.create({ (observer) -> Disposable in
            var a = CardParameters.kDefaultFSMParameters
            let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
            peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
                observer.onNext(true)
            }) { (error) in
                print("!!!! error writing \(data) with error: \(error)")
                observer.onError(error)
                }.disposed(by: self.disposeBag)
            return Disposables.create()
        })

    }
    func writeFindMonitorParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kMFSFindMonitorParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFindMonitorParameters))
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.findMonitorParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            }.disposed(by: disposeBag)
    }
    func turnCardOff(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.cardOff, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            }.disposed(by: disposeBag)
    }
    func decommission(for card: CardModel) {
        if let peripheral = card.peripheral {
            if peripheral.isConnected {
                var a = CardParameters.kDecommissionFSMParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
                let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    print("!!! success write decommission \(String(describing: char.characteristic.value?.hexadecimalString))")
                    self.disconnect(peripheral)
                }) { (error) in
                    print("!!!! error writing decommission \(data) with error: \(error)")
                    }
                disposeBag.insert(disposable)
            }
            else {
                centralManager.centralManager.connect(peripheral.peripheral, options: nil)
                var a = CardParameters.kDecommissionFSMParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
                let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    print("!!! success write decommission \(String(describing: char.characteristic.value?.hexadecimalString))")
                }) { (error) in
                    print("!!!! error writing decommission \(data) with error: \(error)")
                }
                disposeBag.insert(disposable)
                peripheralConnections[peripheral] = disposable
            }
        }
    }
    func turnOnLED(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            }.disposed(by: disposeBag)
    }
    func turnOffLED(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(0)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            }.disposed(by: disposeBag)
    }
}

enum RxBluetoothServiceError: Error {
    
    case redundantStateChange
    
}
