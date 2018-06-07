//
//  MFFirmwareUpdateManager.swift
//  MultipleCardTest
//
//  Created by Siavash on 30/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import RxBluetoothKit

final class MFFirmwareUpdateManager {
  
  static let shared: MFFirmwareUpdateManager = MFFirmwareUpdateManager()
  var needsToUpdateToLatestVersionObserver: Observable<Result<String, Error>> {
    return needsToUpdateToLatestVersionSubject.asObservable().replayAll()
  }
  private(set) var latestFirmwareDataOnDiskVersion: String = ""

  private lazy var otaTarget: String = {
    return "qa"
  }()
  private lazy var cachedFirmwareBinaryPath: URL? = {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      return dir.appendingPathComponent(Constant.FirmwareUpdate.kCachedFirmwareFilename)
    }
    return nil
  }()
  private(set) var firmwareData: Data? 
  private lazy var otaUsername: String = {
    return extractValueFromShuffledText(mode: 77, length: 3)
  }()
  private lazy var otaPasswrod: String = {
    return extractValueFromShuffledText(mode: 81, length: 12)
  }()
  
  private let firmwareObjCHelper: MFFirmwareHelper = MFFirmwareHelper.shared()
  private var nextOTAState: MFSOTAState?
  private var checkInProgress: Bool = false
  private var needsToUpdateToLatestVersionSubject = PublishSubject<Result<String, Error>>()
  
  func startChecking(for monitor: Monitor) {
    self.bind(for: monitor)
  }
  
  // MARK:- Private methods
  private func requestFirmwareUpdate(for version: String) {
    self.requestFirmwareUpdateCheck(for: version, completion: { (updateResult) in
      switch updateResult {
      case .checkingIsInProgress:
        AppDelegate.shared.log.debug("checking for update is InProgress")
      case .isLatest:
        AppDelegate.shared.log.debug("current version is the Latest")
        self.needsToUpdateToLatestVersionSubject.onNext(Result.error(MFFirmwareError.isLatest))
      case .needsToUpdate(let newVersion):
        AppDelegate.shared.log.debug("needs To Update to \(newVersion)")
        self.latestFirmwareDataOnDiskVersion = newVersion
        self.needsToUpdateToLatestVersionSubject.onNext(Result.success(newVersion))
      case .otaServerFailure(let error):
        AppDelegate.shared.log.error("firmware update request: \(error)")
        self.needsToUpdateToLatestVersionSubject.onNext(Result.error(error))
      case .responseError:
        self.needsToUpdateToLatestVersionSubject.onNext(Result.error(MFFirmwareError.responseError))
        AppDelegate.shared.log.error("firmware update request response Error")
      }
    })
  }
  private func bind(for monitor: Monitor) {
    if latestFirmwareDataOnDiskVersion == "" || firmwareData == nil {
      latestFirmwareDataOnDiskVersion = monitor.realmCard.firmwareRevisionString
      requestFirmwareUpdate(for: monitor.realmCard.firmwareRevisionString)
    }
  }
  
  private func requestFirmwareUpdateCheck(for version: String, completion: @escaping (_ result: MFFirmwareUpdateResult) -> Void) {
    if checkInProgress {
      completion(MFFirmwareUpdateResult.checkingIsInProgress)
      return
    }
    checkInProgress = true
    
    let parameters: [String: String] = [
      "environment" : otaTarget,
      "version" : version
    ]
    
    if let request = firmwareVersionCheckRequest(Constant.FirmwareUpdate.otaURL, user: otaUsername, password: otaPasswrod, parameters: parameters) {
      request.validate()
        .responseJSON(completionHandler: { [weak self] response in
          switch response.result {
          case .success:
            if let responseJson = response.result.value as? [String: Any], let isCurrent = responseJson["current"] as? Bool {
              if !isCurrent {
                if let newVersion = responseJson["newVersion"] as? String,
                  let downloadUrl = responseJson["uri"] as? String {
                  self?.download(downloadUrl, completion: {_ in
                    self?.checkInProgress = false
                    UserDefaults.standard.set(Date(), forKey: Constant.FirmwareUpdate.kFirmwareLastUpdateCheckedDateKey)
                  })
                  completion(MFFirmwareUpdateResult.needsToUpdate(version: newVersion))
                  self?.checkInProgress = false
                }
              } else {
                completion(MFFirmwareUpdateResult.isLatest)
                self?.checkInProgress = false
              }
            } else {
              completion(MFFirmwareUpdateResult.responseError)
              self?.checkInProgress = false
            }
          case .failure(let error):
            completion(MFFirmwareUpdateResult.otaServerFailure(error: error))
            self?.checkInProgress = false
          }
        })
    }
  }
  
  private func download(_ urlText: String, completion: @escaping ((_ success: Bool) -> Void)) {
    guard !urlText.isEmpty else {
      return
    }
    
    if let request = firmwareDataDownloadRequest(urlText) {
      request.validate()
        .responseData(completionHandler: {  response in
          switch response.result {
          case .success:
            if let firmwareData = response.result.value {
              debugPrint("Latest version downloaded")
              completion(self.writeFirmewareData(firmwareData))
            }
          case .failure(_):
            completion(false)
          }
          
        })
    }
  }
  
  private func firmwareVersionCheckRequest(_ urlText: URLConvertible, user: String, password: String, parameters: [String : String]) -> DataRequest?
  {
    var headers : [String : String] = [
      "Content-Type": "application/json",
      "Accept": "application/json"
    ]
    if "\(user):\(password)".data(using: String.Encoding.utf8) != nil {
      let base64Credentials = "YXBpOktlZSQudSlUOi1qaw"
      headers["Authorization"] = "Basic \(base64Credentials)"
    }
    
    if let uuidText = UIDevice.current.identifierForVendor?.uuidString {
      headers["x-device-uid"] = uuidText
    }
    
    return Alamofire.request(urlText, method: .get, parameters: parameters, headers: headers)
  }
  
  private func firmwareDataDownloadRequest(_ urlText: URLConvertible) -> DataRequest? {
    let headers : [String : String] = [
      "Content-Type": "application/octet-stream"
    ]
    
    return Alamofire.request(urlText, method: .get, parameters: nil, headers: headers)
  }
  
  private func writeFirmewareData(_ data: Data) -> Bool {
    if let fileURL = cachedFirmwareBinaryPath {
      //writing
      do {
        try data.write(to: fileURL, options: Data.WritingOptions.atomic)
        firmwareData = data
        AppDelegate.shared.log.debug("Latest firmware version written to disk")
        return true
      }
      catch {
        return false
      }
    }
    return false
  }

  private func extractValueFromShuffledText(mode: Int, length: Int) -> String {
    var finalText: String = ""
    let otaShuffledText = Constant.FirmwareUpdate.otaShuffledText
    let otaShuffledTextLen = otaShuffledText.count
    guard (mode <= otaShuffledTextLen) && (mode * length <=  otaShuffledTextLen) else {
      return finalText
    }
    
    for index in 0..<otaShuffledTextLen {
      if (index > 0) && ((index % mode) == 0) {
        finalText = finalText + "\(otaShuffledText[index])"
      }
      
      if finalText.count == length {
        break
      }
    }
    return finalText
  }
}
