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
  
  var shouldHideUpdateButtonObserver: Observable<Bool> {
    return shouldHideUpdateButtonSubject.asObservable()
  }
  var shouldReloadDataObserver: Observable<Bool> {
    return shouldReloadDataSubject.asObservable()
  }
  
  var progressText = Variable<String>("0%")
  
  private var ds: [PeripheralInfoCellData] = [] {
    didSet {
      self.shouldReloadDataSubject.onNext(true)
    }
  }
  
  private var selectedRealmPeripheral: RealmCardPripheral {
    didSet {
      self.shouldReloadDataSubject.onNext(true)
    }
  }
  private var peripheral: Peripheral
  private let updateManager: MFFirmwareUpdateManager = MFFirmwareUpdateManager.shared
  private let firmwareObjCHelper: MFFirmwareHelper = MFFirmwareHelper.shared()
  private var nextOTAState: MFSOTAState?
  private let bag = DisposeBag()
  private var disposabels: [Disposable?] = []
  private var writeDisposables: [Disposable?] = []
  private var charDisposable: Disposable!
  private var shouldHideUpdateButtonSubject = BehaviorRelay(value: false)
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

  func bind(updateBtn: Observable<Void>) {
    let battery = Int(selectedRealmPeripheral.batteryLevel) ?? 0
    let shouldHide = (updateManager.latestFirmwareDataOnDiskVersion == selectedRealmPeripheral.firmwareRevisionString) || battery < 20
    shouldHideUpdateButtonSubject = BehaviorRelay(value: shouldHide)
    updateBtn.subscribe { [weak self] (_) in
      AppDelegate.shared.log.debug("should start OTA")
      // start Update
      self?.otaStatusNotification()
    }.disposed(by: bag)
    
//    MFRxBluetoothKitService.shared.observeDisconnect(for: peripheral)
//    MFRxBluetoothKitService.shared.disconnectionReasonOutput.subscribe(onNext: { (result) in
//      switch result {
//      case .success(let peripheral):
//        MFRxBluetoothKitService.shared.establishConnectionAndAddToConnectionDisposal(for: peripheral)
//      case .error(let error):
//        AppDelegate.shared.log.error("info view model disconnection observer result \(error)")
//      }
//    }, onError: { (error) in
//      AppDelegate.shared.log.error("info view model disconnection observer \(error)")
//    }).disposed(by: bag)

  }
  func title() -> String {
    return selectedRealmPeripheral.uuid
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
  private func writeOTAMemoryType() {
    firmwareObjCHelper.firmwareData = NSMutableData.init(data: MFFirmwareUpdateManager.shared.firmwareData!)
    firmwareObjCHelper.delegate = self
    
    if let data = firmwareObjCHelper.getMemDevData() {
      let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
        AppDelegate.shared.log.debug("writeOTAMemoryType suceess")
      }, onError: { [weak self] (error) in
        AppDelegate.shared.log.error("writeOTAMemoryType :\(error)")
        self?.progressText.value = "writeOTAMemoryType :\(error)"
      })
      writeDisposables.append(disposable)
    }
  }
  private func otaStatusCMPOkay() {
    if let state = nextOTAState {
      switch state {
      case .writePatchLength:
        writePatchLength()
        break
      case .writePatchEnd:
        writePatchEnd()
        break
      case .writePatchData:
        writePatchData()
        break
      case .reboot:
        writeRebootCommand()
        break
      case .patchCompleted:
        AppDelegate.shared.log.debug("Firmware Update Complete")
        progressText.value = "Update completed"
        break
      }
    }
  }
  private func otaStatusUnexpected(value: Int8) {
    AppDelegate.shared.log.error("UNEXPECTED STATUS RESULT")
    if (value == SPOTA_STATUS_VALUES.SAME_IMG_ERR.rawValue) {
      AppDelegate.shared.log.error("Same Image On File Error")
      progressText.value = "Same Image On File Error"
      writeDefaultConnectionParameters()
    }
  }
  private func otaStatusNotification() {
    progressText.value = "Updating...."
    writeFastConnectionParameters().subscribe(onNext: { [weak self] (_) in
      let disposable = self?.peripheral.readValue(for: DeviceCharacteristic.otaStatus)
        .subscribe(onSuccess: { (char) in
          AppDelegate.shared.log.debug("read otaStatus success")
          self?.writeOTAMemoryType()
          self?.charDisposable = char.observeValueUpdateAndSetNotification()
            .subscribe(onNext: { (char) in
              if let newValue = char.value {
                if let value = self?.firmwareObjCHelper.getCharValue(for: NSMutableData.init(data: newValue)) {
                  AppDelegate.shared.log.debug("Notification \(value)")
                  if value == SPOTA_STATUS_VALUES.IMG_STARTED.rawValue {
                    self?.writeMemoryPath()
                  } else if value == SPOTA_STATUS_VALUES.CMP_OK.rawValue {
                    self?.otaStatusCMPOkay()
                  } else {
                    self?.otaStatusUnexpected(value: value)
                  }
                }
              }
            }, onError: { (error) in
              AppDelegate.shared.log.error("notification \(error)")
            })
        }) { (error) in
          self?.progressText.value = "\(error)"
          AppDelegate.shared.log.error("\(error)")
      }
      self?.disposabels.append(disposable)
      self?.disposabels.append(self?.charDisposable)
    }, onError: { [weak self] (error) in
      self?.progressText.value = "write fast connection \(error)"
      AppDelegate.shared.log.error("write fast connection \(error)")
    }).disposed(by: bag)
   
  }

  private func readFirmwareOnUpdateSuccess() {
    progressText.value = "firmware version \(updateManager.latestFirmwareDataOnDiskVersion)"
    ds[2] = PeripheralInfoCellData.init(title: "Firmware", subtitle: updateManager.latestFirmwareDataOnDiskVersion)
    // update the realm object
    if let realm = RealmManager.shared.getRealmObject(for: peripheral) {
      RealmManager.shared.beginWrite()
      realm.firmwareRevisionString = MFFirmwareUpdateManager.shared.latestFirmwareDataOnDiskVersion
      RealmManager.shared.commitWrite()
      RealmManager.shared.addOrUpdate(monitor: (realm, peripheral))
      shouldHideUpdateButtonSubject = BehaviorRelay(value: true)
    }
  }
  private func writeMemoryPath() {
    let data = firmwareObjCHelper.getMemInfoValue()
    let disposable = peripheral.writeValue(data!, for: DeviceCharacteristic.otaMemoryParams, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { [weak self] (_) in
      AppDelegate.shared.log.debug("write suceess memory path")
      self?.loadPatchData()
    }, onError: { [weak self] (error) in
      self?.progressText.value = "wirte :\(error)"
      AppDelegate.shared.log.error("wirte :\(error)")
    })
    writeDisposables.append(disposable)
  }
  private func loadPatchData() {
    firmwareObjCHelper.loadPatchData()
    
  }
  private func writeFastConnectionParameters() -> Observable<Bool> {
    progressText.value = "Writing fast connection params...."
    return Observable.create({ [weak self] (observer) -> Disposable in
      var a = CardParameters.kFastConnectionParameters
      let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters))
      let disposable = self?.peripheral.writeValue(Data(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
          observer.onNext(true)
          self?.progressText.value = "Fast connection params written"
        })
        AppDelegate.shared.log.debug("write suceess fast connectionParameters")
      }, onError: { (error) in
        observer.onError(error)
        self?.progressText.value = "wirte fast connectionParameters :\(error)"
        AppDelegate.shared.log.error("wirte fast connectionParameters :\(error)")
      })
      self?.writeDisposables.append(disposable)
      return Disposables.create()
    })
    
  }
  private func writePatchLength() {
    if let data = firmwareObjCHelper.patchLenghtData() {
      let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaPatchLength, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { [weak self] (_) in
        self?.writePatchData()
      }, onError: { [weak self] (error) in
        self?.progressText.value = "wirte otaPatchLength :\(error)"
        AppDelegate.shared.log.error("wirte otaPatchLength :\(error)")
      })
      writeDisposables.append(disposable)
    }

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
    AppDelegate.shared.log.debug("write reboot command")
    //Request to set slow parameters before reboot.
    AppDelegate.shared.log.debug("OTA: Before reboot card, set slow parameter.")
    writeDefaultConnectionParameters()
    readFirmwareOnUpdateSuccess()
  }
}
extension PeripheralInfoViewModel: MFFirmwareHelperDelegate {
  func progress(_ progress: Int32) {
    progressText.value = "\(progress)%"
  }
  func updateStateToMFS_OTA_State_PatchCompleted() {
    nextOTAState = MFSOTAState.patchCompleted
    if let data = firmwareObjCHelper.rebootCommandData() {
      let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
      }) { [weak self] (error) in
        AppDelegate.shared.log.error("write updateStateToMFS_OTA_State_PatchCompleted error \(error)")
        self?.progressText.value = "write updateStateToMFS_OTA_State_PatchCompleted error \(error)"
      }
      writeDisposables.append(disposable)
    }

  }
  
  func writeDefaultConnectionParameters() {
    var a = CardParameters.kDefaultConnectionParameters
    let data = NSData.init(bytes: &a, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters))
    let disposable = peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { [weak self] (char) in
      AppDelegate.shared.log.debug("write Default Connection Parameters success")
      let data = self?.firmwareObjCHelper.rebootCommandData()
      self?.writePatchEnd(data)
    }) { [weak self] (error) in
      AppDelegate.shared.log.error("write Default Connection Parameters error \(error)")
      self?.progressText.value = "write Default Connection Parameters error \(error)"
    }
    writeDisposables.append(disposable)
  }
  
  func updateStateToMFS_OTA_State_Reboot() {
    nextOTAState = MFSOTAState.reboot
  }
  
  func writePatchEnd(_ data: Data!) {
    let disposable = peripheral.writeValue(data, for: DeviceCharacteristic.otaMemoryType, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (_) in
      AppDelegate.shared.log.debug("write suceess otaMemoryType path")
    }, onError: { (error) in
      AppDelegate.shared.log.error("wirte otaMemoryType :\(error)")
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
      AppDelegate.shared.log.error("wirte otaPatchData :\(error)")
    })
    writeDisposables.append(disposable)
  }
}
