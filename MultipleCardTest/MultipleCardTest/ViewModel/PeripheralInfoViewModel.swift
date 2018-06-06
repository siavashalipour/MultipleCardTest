//
//  PeripheralInfoViewModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 18/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit
import CoreBluetooth
import RxSwift
import RxCocoa

class PeripheralInfoViewModel {
    
    private var ds: [PeripheralInfoCellData] = [] {
        didSet {
            self.shouldReloadDataSubject.onNext(true)
        }
    }
    
    private var selectedRealmPeripheral: RealmCardPripheral
    private var peripheral: Peripheral
    private let updateManager: MFFirmwareUpdateManager = MFFirmwareUpdateManager.shared
    private let firmwareObjCHelper: MFFirmwareHelper = MFFirmwareHelper.shared()
    private var nextOTAState: MFSOTAState?
    private var disposable: Disposable?
    private let bag = DisposeBag()
    private var disposabels: [Disposable?] = []
    private var writeDisposables: [Disposable?] = []
    private var charDisposable: Disposable!
    var shouldHideUpdateButtonObserver: Observable<Bool> {
        return shouldHideUpdateButtonSubject.asObservable()
    }
    var shouldReloadDataObserver: Observable<Bool> {
        return shouldReloadDataSubject.asObservable()
    }
    
    private var shouldHideUpdateButtonSubject = BehaviorRelay(value: false)
    var progressText = Variable<String>("0%")
    
    private var shouldReloadDataSubject = PublishSubject<Bool>()
    
    init(with monitor: Monitor) {
        self.selectedRealmPeripheral = monitor.realmCard
        let realmPeripheral = monitor.realmCard
        var item = PeripheralInfoCellData.init(title: "Battery", subtitle: realmPeripheral.batteryLevel + "%")
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "MACAddress", subtitle: realmPeripheral.MACAddress)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Firmware", subtitle: realmPeripheral.firmwareRevisionString)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "FSM", subtitle: realmPeripheral.fsmParameters)
        ds.append(item)
        item = PeripheralInfoCellData.init(title: "Connection", subtitle: realmPeripheral.connectionParameters)
        ds.append(item)
        self.peripheral = monitor.peripheral
        
    }
    public func bind(updateBtn: Observable<Void>) {
        observeDisconnect()
        shouldHideUpdateButtonSubject = BehaviorRelay(value: updateManager.latestFirmwareDataOnDiskVersion == selectedRealmPeripheral.firmwareRevisionString)
        _ = updateBtn.subscribe { (_) in
            print("should start OTA")
            // start Update
            self.otaStatusNotification()

            if self.peripheral.isConnected {
            } else {
                self.disposabels.append(self.peripheral.establishConnection().subscribe({ (_) in
                    self.otaStatusNotification()
                }))
            }
        }
    }
    private func writeOTAMemoryType() {
        firmwareObjCHelper.firmwareData = NSMutableData.init(data: MFFirmwareUpdateManager.shared.firmwareData!)
        firmwareObjCHelper.delegate = self
        
        let disposable = self.writeFastConnectionParameters().subscribe({ (_) in
            let data = self.firmwareObjCHelper.getMemDevData()
            let disposable = self.peripheral.writeValue(data!, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
                debugPrint("!!! write suceess")
            }, onError: { (error) in
                debugPrint("!!! wirte :\(error)")
                self.progressText.value = "!!! wirte :\(error)"
            })
            self.writeDisposables.append(disposable)
        })
        writeDisposables.append(disposable)
    }

    private func otaStatusNotification() {
        progressText.value = "Updating...."

        let disposable = peripheral.readValue(for: DeviceCharacteristic.otaStatus)
            .subscribe(onSuccess: { (char) in
                print("!! read otaStatus success")
                self.writeOTAMemoryType()
                self.charDisposable = char.observeValueUpdateAndSetNotification()
                    .subscribe(onNext: { (char) in
                        let newValue = char.value
                        let value = self.firmwareObjCHelper.getCharValue(for: NSMutableData.init(data: newValue!))
                        print("!!! Notification \(value)")
                        if value == SPOTA_STATUS_VALUES.IMG_STARTED.rawValue {
                            self.writeMemoryPath()
                        } else if value == SPOTA_STATUS_VALUES.CMP_OK.rawValue {
                            print("CMP OKAY")
                            if let state = self.nextOTAState {
                                switch state {
                                case .writePatchLength:
                                    self.writePatchLength()
                                    break
                                case .writePatchEnd:
                                    self.writePatchEnd()
                                    break
                                case .writePatchData:
                                    self.writePatchData()
                                    break
                                case .reboot:
                                    self.writeRebootCommand()
                                    break
                                case .patchCompleted:
                                    print("Firmware Update Complete")
                                    self.progressText.value = "Update completed"
                                    self.readFirmware()
                                    break
                                }
                            }
                        } else {
                            print("************************")
                            print("UNEXPECTED STATUS RESULT")
                            print("************************")
                            
                            if (value == SPOTA_STATUS_VALUES.SAME_IMG_ERR.rawValue) {
                                print("Same Image On File Error")
                                self.progressText.value = "Same Image On File Error"
                                self.writeDefaultConnectionParameters()
                            }
                        }
                    }, onError: { (error) in
                        self.progressText.value = "notification \(error)"
                        AppDelegate.shared.log.error("notification \(error)")
                    })
                        
                            
            }) { (error) in
                self.progressText.value = "\(error)"
                AppDelegate.shared.log.error("\(error)")
        }
        disposabels.append(disposable)
    }
    private func observeDisconnect() {
        peripheral.observeConnection()
            .subscribe(onNext: { (isConnected) in
                print("!!!! STATUS \(isConnected)")
                if !isConnected {
                    self.peripheral.establishConnection().subscribe(onNext: { (_) in
                        self.readFirmware()
                    }, onError: { (error) in
                        AppDelegate.shared.log.error("establsih connection: \(error)")
                    }).disposed(by: self.bag)
                }
            }, onError: { (error) in
                AppDelegate.shared.log.error("Observer conncetion: \(error)")
            }).disposed(by: bag)
    }
    private func readFirmware() {
        progressText.value = "Reading firmware version"
        let disposable = MFRxBluetoothKitService.shared.readFirmwareVersion(for: peripheral)
            .subscribe(onNext: { (result) in
                switch result {
                case .success(let version):
                    self.ds[2] = PeripheralInfoCellData.init(title: "Firmware", subtitle: version)
                    // update the realm object
                    if let realm = RealmManager.shared.getRealmObject(for: self.peripheral) {
                        RealmManager.shared.beginWrite()
                        realm.firmwareRevisionString = version
                        RealmManager.shared.commitWrite()
                        RealmManager.shared.addOrUpdate(monitor: (realm, self.peripheral))
                    }
                case .error(_):
                    break
                }
            }, onError: { (error) in
                self.progressText.value = "\(error)"
            })
        disposabels.append(disposable)
    }
    private func writeMemoryPath() {
        let data = firmwareObjCHelper.getMemInfoValue()
        let disposable = peripheral.writeValue(data!, for: DeviceCharacteristic.otaMemoryParams, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
            debugPrint("!!! write suceess memory path")
            self.loadPatchData()
        }, onError: { (error) in
            self.progressText.value = "!!! wirte :\(error)"
            debugPrint("!!! wirte :\(error)")
        })
        writeDisposables.append(disposable)
    }
    private func loadPatchData() {
        firmwareObjCHelper.loadPatchData()
        
    }
    func writeFastConnectionParameters() -> Observable<Bool> {
        return Observable.create({ (observer) -> Disposable in
            var a = CardParameters.kFastConnectionParameters
            let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters))
            let disposable = self.peripheral.writeValue(Data(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    observer.onNext(true)
                })
                debugPrint("!!! write suceess fast connectionParameters")
            }, onError: { (error) in
                observer.onError(error)
                self.progressText.value = "!!! wirte fast connectionParameters :\(error)"
                debugPrint("!!! wirte fast connectionParameters :\(error)")
            })
            self.writeDisposables.append(disposable)
            return Disposables.create()
        })

    }
    private func writePatchLength() {
        let data = firmwareObjCHelper.patchLenghtData()
        let disposable = peripheral.writeValue(data!, for: DeviceCharacteristic.otaPatchLength, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
            self.writePatchData()
        }, onError: { (error) in
            self.progressText.value = "!!! wirte otaPatchLength :\(error)"
            debugPrint("!!! wirte otaPatchLength :\(error)")
        })
        writeDisposables.append(disposable)
    }
    private func writePatchEnd() {
        firmwareObjCHelper.writePatchEnd()
        
    }
    private func writePatchData() {
        firmwareObjCHelper.writePatchData()
    }
    private func writeRebootCommand() {
        // step 7
        // Send reboot signal to device
        print("!!! write reboot command")
        //Request to set slow parameters before reboot.
        print("OTA: Before reboot card, set slow parameter.")
        writeDefaultConnectionParameters()
    }
    
    func numberOfItems() -> Int {
        return ds.count
    }
    func item(at indexPath: IndexPath) -> PeripheralInfoCellData? {
        if indexPath.row < ds.count {
            return ds[indexPath.row]
        }
        return nil 
    }
}
extension PeripheralInfoViewModel: MFFirmwareHelperDelegate {
    func progress(_ progress: Int32) {
        progressText.value = "\(progress )%"
    }
    func updateStateToMFS_OTA_State_PatchCompleted() {
        nextOTAState = MFSOTAState.patchCompleted
        let data = firmwareObjCHelper.rebootCommandData()
        readFirmware()

        let disposable = peripheral.writeValue(data!, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
        }) { (error) in
            print("write updateStateToMFS_OTA_State_PatchCompleted error \(error)")
            self.progressText.value = "write updateStateToMFS_OTA_State_PatchCompleted error \(error)"
        }
        writeDisposables.append(disposable)
    }
    
    func writeDefaultConnectionParameters() {
        var a = CardParameters.kDefaultConnectionParameters
        let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters))
        let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("write Default Connection Parameters success")
            let data = self.firmwareObjCHelper.rebootCommandData()
            self.writePatchEnd(data)
        }) { (error) in
            print("write Default Connection Parameters error \(error)")
            self.progressText.value = "write Default Connection Parameters error \(error)"
        }
        writeDisposables.append(disposable)
    }
    
    func updateStateToMFS_OTA_State_Reboot() {
        nextOTAState = MFSOTAState.reboot
    }
    
    func writePatchEnd(_ data: Data!) {
        readFirmware()
        let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
            debugPrint("!!! write suceess otaMemoryType path")
        }, onError: { (error) in
            debugPrint("!!! wirte otaMemoryType :\(error)")
        })
        writeDisposables.append(disposable)
    }
    
    func loadPatchDataDone(_ data: Data!) {
        self.writePatchLength()
    }
    
    func updateStateToMFS_OTA_State_WritePatchData() {
        nextOTAState = MFSOTAState.writePatchData
    }
    
    func updateStateToMFS_OTA_State_WritePatchEnd() {
        nextOTAState = MFSOTAState.writePatchEnd
    }
    
    func updateStateToMFS_OTA_State_WritePatchLength() {
        nextOTAState = MFSOTAState.writePatchLength
    }
    
    func writeOtaPatchDataPath(_ data: Data!) {
        let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaPatchData, type: CBCharacteristicWriteType.withoutResponse).subscribe(onSuccess: { (_) in
        }, onError: { (error) in
            debugPrint("!!! wirte otaPatchData :\(error)")
        })
        writeDisposables.append(disposable)
    }
}
