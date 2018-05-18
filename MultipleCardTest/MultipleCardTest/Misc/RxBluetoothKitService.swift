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

final class RxBluetoothKitService {
    
    typealias Disconnection = (Peripheral, DisconnectionReason?)
    private let kRSSIThreshold: Double = -50
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
        return reConnectionSubject.share(replay: 1, scope: .forever).asObservable()
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
    private var peripheralConnectionObserver: Observable<Peripheral>?
    
    private let centralManager = CentralManager(queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "some.very.unique.key" as AnyObject])
    
    private let scheduler: ConcurrentDispatchQueueScheduler
    
    private let disposeBag = DisposeBag()
    
    private var peripheralConnections: [Peripheral: Disposable] = [:]
    
    private var scanningDisposable: Disposable!
    
    private var connectionDisposable: Disposable!
    
    private var notificationDisposables: [Characteristic: Disposable] = [:]
    
    // MARK: - Initialization
    init() {
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
            .timeout(40.0, scheduler: scheduler)
            .take(1)
            .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                guard let `self` = self else {
                    return Observable.empty()
                }
                return self.centralManager.scanForPeripherals(withServices: nil)
            }.subscribe(onNext: { [weak self] scannedPeripheral in
                let canConnect = scannedPeripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scannedPeripheral.rssi.doubleValue > (self?.kRSSIThreshold)!
                    
                if canConnect && scannedPeripheral.peripheral.state != .connected {
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
        _ = peripheralsToReConnect.map({
            $0.establishConnection().subscribe(onNext: { (peripheral) in
                self.reConnectionSubject.onNext(Result.success(peripheral))
            }, onError: { (error) in
                self.reConnectionSubject.onNext(Result.error(error))
            }).disposed(by: disposeBag)
        })
        
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
    private func observeDisconnect(for peripheral: Peripheral) {
        centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
            self.disconnectionSubject.onNext(Result.success((peripheral, reason)))
            self.disconnect(peripheral)
            }, onError: { [unowned self] error in
                self.disconnectionSubject.onNext(Result.error(error))
        }).disposed(by: disposeBag)
    }
    
    func instantiatePeripheralConnectionObserver(for card: CardModel) {
        if peripheralConnectionObserver != nil {
            return
        }
        if let peripheral = card.peripheral {
            peripheralConnectionObserver = peripheral.establishConnection()
        }
    }
}
// MARK:- Readings
extension RxBluetoothKitService {
    func readMACAddress(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        instantiatePeripheralConnectionObserver(for: card)
        _ = peripheralConnectionObserver?.subscribe { (_) in
            peripheral.readValue(for: DeviceCharacteristic.MACAddress)
                .subscribe(onSuccess: { (char) in
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
                        self.macAddressSubject.onNext(Result.success(macAddress))
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("MAC \(error)")
                    self.macAddressSubject.onNext(Result.error(error))
                }.disposed(by: self.disposeBag)
        }
    }
    func readBattery(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        instantiatePeripheralConnectionObserver(for: card)
        _ = peripheralConnectionObserver?.subscribe({ (_) in
            peripheral.readValue(for: DeviceCharacteristic.batteryLevel)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        self.batterySubject.onNext(Result.success("\(value[0])"))
                    }
                }) { (error) in
                    print("Bat \(error)")
                    self.batterySubject.onNext(Result.error(error))
                }.disposed(by: self.disposeBag)
        })
    }
    func readFirmwareVersion(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        instantiatePeripheralConnectionObserver(for: card)
        _ = peripheralConnectionObserver?.subscribe({ (_) in
            peripheral.readValue(for: DeviceCharacteristic.firmwareRevisionString)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let firmware = String.init(data: value, encoding: String.Encoding.utf8)
                        self.firmwareVersionSubject.onNext(Result.success(firmware ?? "wrong encoding"))
                    }
                }) { (error) in
                    print("Firm \(error)")
                    self.firmwareVersionSubject.onNext(Result.error(error))
                }.disposed(by: self.disposeBag)
        })
    }
    func readFSMParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        instantiatePeripheralConnectionObserver(for: card)
        _ = peripheralConnectionObserver?.subscribe({ (_) in
            peripheral.readValue(for: DeviceCharacteristic.fsmParameters)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let str = value.hexadecimalString
                        self.fsmParamsSubject.onNext(Result.success(str))
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("fsm \(error)")
                    self.fsmParamsSubject.onNext(Result.error(error))
                }.disposed(by: self.disposeBag)
        })
    }
    func readConnectionParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        instantiatePeripheralConnectionObserver(for: card)
        _ = peripheralConnectionObserver?.subscribe({ (_) in
            peripheral.readValue(for: DeviceCharacteristic.connectionParameters)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let str = value.hexadecimalString
                        self.connectionParamsSubject.onNext(Result.success(str))
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("param \(error)")
                    self.connectionParamsSubject.onNext(Result.error(error))
                }.disposed(by: self.disposeBag)
        })
    }
}
// MARK:- Writings
extension RxBluetoothKitService {
    func writeDefaultConnectionParameters(for card: CardModel) { // commissioning
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kDefaultConnectionParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSConnectionParameters))
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
            }
            }.disposed(by: disposeBag)
    }
    func writeFSMParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kDefaultFSMParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    func writeFindMonitorParameters(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kMFSFindMonitorParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFindMonitorParameters))
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.findMonitorParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    func turnCardOff(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.cardOff, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    func decommission(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a = CardParameters.kDecommissionFSMParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    func turnOnLED(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    func turnOffLED(for card: CardModel) {
        guard let peripheral = card.peripheral else { return }
        var a: UInt8 = UInt8(0)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
//        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
}
// MARK:- Card binding Flow
extension RxBluetoothKitService {
    func startCardBinding(for card: CardModel) {
//        Read the FW battery
//        Read the FW version
//        Write the battery notifications ON
//        Write the Connection parameters
//        Write the FSM parameters
    }
    
    func reconnectOrTurnOnCard(_ card: CardModel) {
//        Read the FW battery
//        Read the FW version
//        Write the battery notifications ON
//        Diagnostic read of FSM parameters
//        Write the Connection parameters
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
    
    func unlink(_ card: CardModel) {
//        App (Master) writes the FSM parameters (to make the card Un-commissioned)
//        Card (Slave/FW) sends the response and App waits for the response
//            Card sends the termination link to the App
//        App sends the termination link to the Card
    }
    
    func trunOff(_ card: CardModel) {
//        App (Master) writes the PM0 mode (flight mode) to the card
//        Card (Slave/FW) sends the response and App waits for the response
//        Card sends the termination link to the App
    }
}
enum RxBluetoothServiceError: Error {
    
    case redundantStateChange
    
}
