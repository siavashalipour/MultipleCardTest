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
    
    var reConnectionOutput: Observable<Result<CardModel, Error>> {
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
    var setBatteryNotificationObserver: Observable<Result<Bool, Error>> {
        return setBatteryNotificationSubject.asObservable()
    }
    var cardBindingObserver: Observable<Result<CardModel, Error>> {
        return cardBindingSubject.asObservable()
    }
    var turnOffCardObserver: Observable<Result<Bool, Error>> {
        return turnOffCardSubject.asObservable()
    }
    var unlinkingObserver: Observable<Result<Bool, Error>> {
        return unlinkingSubject.asObservable()
    }
    // MARK: - Private fields
    private let scanningSubject = PublishSubject<Result<ScannedPeripheral, Error>>()
    private let discoveredServicesSubject = PublishSubject<Result<[Service], Error>>()
    private let disconnectionSubject = PublishSubject<Result<Disconnection, Error>>()
    private let readValueSubject = PublishSubject<Result<Characteristic, Error>>()
    private let writeValueSubject = PublishSubject<Result<Characteristic, Error>>()
    private let updatedValueAndNotificationSubject = PublishSubject<Result<Characteristic, Error>>()
    private let reConnectionSubject = PublishSubject<Result<CardModel, Error>>()
    private let cardBindingSubject = PublishSubject<Result<CardModel, Error>>()
    private let batterySubject = PublishSubject<Result<String, Error>>()
    private let macAddressSubject = PublishSubject<Result<String, Error>>()
    private let fsmParamsSubject = PublishSubject<Result<String, Error>>()
    private let firmwareVersionSubject = PublishSubject<Result<String, Error>>()
    private let connectionParamsSubject = PublishSubject<Result<String, Error>>()
    private let setBatteryNotificationSubject = PublishSubject<Result<Bool, Error>>()
    private let turnOffCardSubject = PublishSubject<Result<Bool, Error>>()
    private let unlinkingSubject = PublishSubject<Result<Bool, Error>>()
    private let discoveredCharacteristicsSubject = PublishSubject<Result<[Characteristic], Error>>()
    private let centralManager = CentralManager(queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "some.very.unique.key" as AnyObject])
    private let scheduler: ConcurrentDispatchQueueScheduler
    private let disposeBag = DisposeBag()
    private var peripheralConnections: [Peripheral: Disposable] = [:]
    private var scanningDisposable: Disposable?
    private var connectionDisposable: Disposable?
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
            .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                guard let `self` = self else {
                    return Observable.empty()
                }
                return self.centralManager.scanForPeripherals(withServices: nil)
            }
            .subscribe(onNext: { [weak self] scannedPeripheral in
                let canConnect = scannedPeripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scannedPeripheral.rssi.doubleValue > (self?.kRSSIThreshold)!
                if canConnect {
                    self?.scanningSubject.onNext(Result.success(scannedPeripheral))
                }
                }, onError: { [weak self] error in
                    self?.scanningSubject.onNext(Result.error(error))
            })
    }
    func tryReconnect(to peripherals: [UUID], realmPeripheral:  Results<RealmCardPripheral>) {
        let peripheralsToReConnect = self.centralManager.retrievePeripherals(withIdentifiers: peripherals)
        if peripheralsToReConnect.count < 1 {
            reConnectionSubject.onNext(Result.error(BluetoothServicesError.peripheralNil))
        }
        if let realmObj = realmPeripheral.first {
            // since it is reconnect notify the view to update before waiting for reading to be finished
            let card = CardModel.init(name: realmObj.cardName, uuid: realmObj.uuid, isConnected: true, MACAddress: realmObj.MACAddress, firmwareRevisionString: realmObj.firmwareRevisionString, batteryLevel: realmObj.batteryLevel, connectionParameters: realmObj.connectionParameters, fsmParameters: realmObj.fsmParameters, peripheral: nil)
            self.reConnectionSubject.onNext(Result.success(card))
        }
        for peripheral in peripheralsToReConnect {
            let disposable = peripheral.establishConnection().subscribe({ (event) in
                if let peripheral = event.element {
                    print(peripheral.isConnected)
                    if peripheral.isConnected {
                        let card = CardModel.init(name: "\(peripheral.name ?? "")", uuid: peripheral.identifier.uuidString, isConnected: true, MACAddress: "", firmwareRevisionString: "", batteryLevel: "", connectionParameters: "", fsmParameters: "", peripheral: peripheral)
                        self.reconnectOrTurnOnCard(card)
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
    private func readMACAddress(for card: CardModel) {
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
    private func readBattery(for card: CardModel) {
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
    
    private func setBatteryNotificationOn(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
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
                    print("Bat setNotification Success")
                    self?.setBatteryNotificationSubject.onNext(Result.success(true))
                }, onError: { [weak self] error in
                    print("bat setNotification \(error)")
                    self?.setBatteryNotificationSubject.onNext(Result.error(error))
            })
        
        if isConnected {
            disposeBag.insert(disposable)
        } else {
            peripheralConnections[peripheral] = disposable
        }
        
    }
    
    private func readFirmwareVersion(for card: CardModel) {
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
    
    private func readFSMParameters(for card: CardModel) {
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
    
    private func readConnectionParameters(for card: CardModel) {
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
    private func writeDefaultConnectionParameters(for card: CardModel) -> Observable<Result<String, Error>> {
        return Observable.create { (observer) -> Disposable in
            if let peripheral = card.peripheral {
                var a = CardParameters.kDefaultConnectionParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSConnectionParameters))
                peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                        let str = char.characteristic.value?.hexadecimalString
                        observer.onNext(Result.success(str ?? ""))
                        print("Default: \(str ?? "")")
                    print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
                }) { (error) in
                    print("!!!! error writing \(data) with error: \(error)")
                    observer.onNext(Result.error(error))
                    }.disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }

    }
    private func writeFSMParameters(for card: CardModel) -> Observable<Result<String, Error>> {
        return Observable.create({ (observer) -> Disposable in
            if let peripheral = card.peripheral {
                var a = CardParameters.kDefaultFSMParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
                peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    let str = char.characteristic.value?.hexadecimalString
                    observer.onNext(Result.success(str ?? ""))
                    print("FSM: \(str ?? "")")
                }) { (error) in
                    print("!!!! error writing \(data) with error: \(error)")
                    observer.onNext(Result.error(error))
                    }.disposed(by: self.disposeBag)
            }
            return Disposables.create()
        })

    }
    private func writeFindMonitorParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kMFSFindMonitorParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFindMonitorParameters))
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.findMonitorParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            }.disposed(by: disposeBag)
    }
    func decommission(for card: CardModel) {
            unlink(card)
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

// MARK:- Card binding Flow
extension RxBluetoothKitService {
    func startCardBinding(for card: CardModel) {
        readBattery(for: card)
        readFirmwareVersion(for: card)
        setBatteryNotificationOn(for: card)
        //Write the Connection parameters
        let defaultWriteObserver = writeDefaultConnectionParameters(for: card)
        let fsmObserver = writeFSMParameters(for: card)
        
        let zip = Observable.zip(batteryObserver, firmwareVersionObserver, defaultWriteObserver, fsmObserver) {
                return (batteryLevel: $0, firmware: $1, defaultWrite: $2, fsm: $3)
            }
        
        var cardCopy = card
        zip.subscribe(onNext: { (batteryLevel, firmware, defaultWrite, fsm) in
            switch batteryLevel {
            case .success(let battery):
                cardCopy.batteryLevel = battery
            case .error(let error):
                self.cardBindingSubject.onNext(Result.error(error))
                break
            }
            
            switch fsm {
            case .success(let fsm):
                cardCopy.fsmParameters = fsm
            case .error(let error):
                self.cardBindingSubject.onNext(Result.error(error))
                break
            }
            switch defaultWrite {
            case .success(let connection):
                cardCopy.connectionParameters = connection
            case .error(let error):
                self.cardBindingSubject.onNext(Result.error(error))
                break
            }
            switch firmware {
            case .success(let firmware):
                cardCopy.firmwareRevisionString = firmware
            case .error(let error):
                self.cardBindingSubject.onNext(Result.error(error))
                break
            }
            self.cardBindingSubject.onNext(Result.success(cardCopy))
        }, onError: { (error) in
            self.cardBindingSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
    }
    
    func reconnectOrTurnOnCard(_ card: CardModel) {
        readBattery(for: card)
        readFirmwareVersion(for: card)
        setBatteryNotificationOn(for: card)
        readFSMParameters(for: card)
        let defaultWriteObserver = writeDefaultConnectionParameters(for: card)
        
        let zip = Observable.zip(batteryObserver, firmwareVersionObserver, setBatteryNotificationObserver, defaultWriteObserver) {
            return (batteryLevel: $0, firmware: $1, batteryNotification: $2, defaultWrite: $3)
        }
        var cardCopy = card
        zip.subscribe(onNext: { (batteryLevel, firmware, batteryNotification, defaultWrite) in
            switch batteryLevel {
            case .success(let battery):
                cardCopy.batteryLevel = battery
            case .error(let error):
                self.reConnectionSubject.onNext(Result.error(error))
                break
            }
            switch defaultWrite {
            case .success(let connection):
                cardCopy.connectionParameters = connection
            case .error(let error):
                self.reConnectionSubject.onNext(Result.error(error))
                break
            }
            switch firmware {
            case .success(let firmware):
                cardCopy.firmwareRevisionString = firmware
            case .error(let error):
                self.reConnectionSubject.onNext(Result.error(error))
                break
            }
            self.reConnectionSubject.onNext(Result.success(cardCopy))
        }, onError: { (error) in
            self.reConnectionSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
        
    }
    
    func doOTA(for card: CardModel) {
        //        App (Master) reads the FW battery
        //        App (Master) writes the Faster connection parameters as follows
        //        Min Interval = 16
        //        Max Interval = 32
        //        Slave Latency = 2
        //        Timeout = 1s
        //        App proceed the OTA (OTA packets exchange)
        //        App writes the slow parameters to the card
        //        App re-boots the card (Disconnection takes place)
        //        App re-connects with the card (Re-connection flow comes into action)
    }
    
    private func unlink(_ card: CardModel) {
        if let peripheral = card.peripheral {
            if peripheral.isConnected {
                var a = CardParameters.kDecommissionFSMParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
                let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    print("!!! success write decommission \(String(describing: char.characteristic.value?.hexadecimalString))")
                    self.disconnect(peripheral)
                    self.unlinkingSubject.onNext(Result.success(true))
                }) { (error) in
                    print("!!!! error writing decommission \(data) with error: \(error)")
                    self.unlinkingSubject.onNext(Result.error(error))
                }
                disposeBag.insert(disposable)
            }
            else {
                centralManager.centralManager.connect(peripheral.peripheral, options: nil)
                var a = CardParameters.kDecommissionFSMParameters
                let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
                let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                    print("!!! success write decommission \(String(describing: char.characteristic.value?.hexadecimalString))")
                    self.disconnect(peripheral)
                    self.unlinkingSubject.onNext(Result.success(true))
                }) { (error) in
                    print("!!!! error writing decommission \(data) with error: \(error)")
                    self.unlinkingSubject.onNext(Result.error(error))
                }
                disposeBag.insert(disposable)
                peripheralConnections[peripheral] = disposable
            }
        }
    }
    
    func trunOff(_ card: CardModel) {
        if let peripheral = card.peripheral {
            var a: UInt8 = UInt8(1)
            let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
            
            peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.cardOff, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
                print("!!! success write turn off \(String(describing: char.characteristic.value?.hexadecimalString))")
                self.turnOffCardSubject.onNext(Result.success(true))
            }) { (error) in
                print("!!!! error writing turn off \(data) with error: \(error)")
                self.turnOffCardSubject.onNext(Result.error(error))
                }.disposed(by: disposeBag)
        }
    }
}


enum RxBluetoothServiceError: Error {
    
    case redundantStateChange
    
}
