//
//  PeripheralInfoViewController.swift
//  MultipleCardTest
//
//  Created by Siavash on 16/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import RxBluetoothKit
import RxSwift

final class PeripheralInfoViewController: UIViewController {
    
    var peripheral: Peripheral! {
        didSet {
            title = "\(peripheral.peripheral.identifier)"
            fetchData()
        }
    }
    private let disposeBag = DisposeBag()
    var ds: [PeripheralInfoCellData] = [] {
        didSet {
            tableView.reloadData()
            scanningHelperView.shouldShowConnected(false)
            scanningHelperView.updateSubtitle(to: "Connecting...")
            if ds.count > 3 {
                scanningHelperView.isHidden = true
            }
        }
    }
    var ds2: [PeripheralInfoCellData] = [
        PeripheralInfoCellData(title: "writeFastConnectionParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kFastConnectionParameters, length: Int(kSizeofMFSConnectionParameters)))"),
        PeripheralInfoCellData(title: "writeFSMParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kDefaultFSMParameters, length: Int(kSizeofMFSFSMParameters)))"),
        PeripheralInfoCellData(title: "writeFindMonitorParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kMFSFindMonitorParameters, length: Int(kSizeofMFSFindMonitorParameters)))"),
        PeripheralInfoCellData(title: "decommission",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kDecommissionFSMParameters, length: Int(kSizeofMFSFSMParameters)))"),
        PeripheralInfoCellData(title: "turnCardOff", subtitle: "1"),
        PeripheralInfoCellData(title: "turnOnLED", subtitle: "1"),
        PeripheralInfoCellData(title: "turnOffLED", subtitle: "0")
    ]
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PeripheralInfoCell.self, forCellReuseIdentifier: String(describing: PeripheralInfoCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = nil
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()
    private lazy var selectableTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PeripheralInfoCell.self, forCellReuseIdentifier: String(describing: PeripheralInfoCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = nil
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.tag = 2 
        return tableView
    }()
    
    private lazy var scanningHelperView: ScanningHelperView = {
        let view = ScanningHelperView()
        view.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        view.isHidden = false
        return view
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(selectableTableView)
        view.addSubview(scanningHelperView)

        tableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(selectableTableView.snp.height)
        }
        selectableTableView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(2)
        }
        scanningHelperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 220, height: 160))
        }
    }
    
    private func fetchData() {
        var item: PeripheralInfoCellData = PeripheralInfoCellData(title: "", subtitle: "")
        peripheral.establishConnection().subscribe { (_) in
            self.scanningHelperView.shouldShowConnected(false)
            self.scanningHelperView.updateSubtitle(to: "Connecting...")
            self.peripheral.readValue(for: DeviceCharacteristic.MACAddress)
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
                        item = PeripheralInfoCellData(title: "MACAddress", subtitle: macAddress)
                        DispatchQueue.main.async {
                            self.ds.append(item)
                        }
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("MAC \(error)")
                }.disposed(by: self.disposeBag)
            
            self.peripheral.readValue(for: DeviceCharacteristic.firmwareRevisionString)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let firmware = String.init(data: value, encoding: String.Encoding.utf8)
                        item = PeripheralInfoCellData(title: "Firmware version", subtitle: firmware ?? "wrong encoding")
                        DispatchQueue.main.async {
                            self.ds.append(item)
                        }
                    }
                    
                }) { (error) in
                    print("Firm \(error)")
                }.disposed(by: self.disposeBag)
            self.peripheral.readValue(for: DeviceCharacteristic.batteryLevel)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        item = PeripheralInfoCellData.init(title: "Battery", subtitle: "\(value[0])%")
                        DispatchQueue.main.async {
                            self.ds.append(item)
                        }
                    }
                }) { (error) in
                    print("Bat \(error)")
                }.disposed(by: self.disposeBag)
            
            self.peripheral.readValue(for: DeviceCharacteristic.connectionParameters)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let str = value.hexadecimalString
                        item = PeripheralInfoCellData(title: "Connection Params", subtitle: str)
                        DispatchQueue.main.async {
                            self.ds.append(item)
                        }
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("param \(error)")
                }.disposed(by: self.disposeBag)
            
            self.peripheral.readValue(for: DeviceCharacteristic.fsmParameters)
                .subscribe(onSuccess: { (char) in
                    if let value = char.characteristic.value {
                        let str = value.hexadecimalString
                        item = PeripheralInfoCellData(title: "fsmParameters", subtitle: str)
                        DispatchQueue.main.async {
                            self.ds.append(item)
                        }
                    }
                    print(char.characteristic.value!.hexadecimalString)
                }) { (error) in
                    print("fsm \(error)")
                }.disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

    }
    
    private func writeFastConnectionParameters() { 
        var a = CardParameters.kFastConnectionParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSConnectionParameters))
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }.disposed(by: disposeBag)
    }
    
    private func writeDefaultConnectionParameters() { // commissioning
        var a = CardParameters.kDefaultConnectionParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSConnectionParameters))
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.connectionParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func writeFSMParameters() {
        var a = CardParameters.kDefaultFSMParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func writeFindMonitorParameters() {
        var a = CardParameters.kMFSFindMonitorParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFindMonitorParameters))
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.findMonitorParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func turnCardOff() {
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.cardOff, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func decommission() {
        var a = CardParameters.kDecommissionFSMParameters
        let data = NSData.init(bytes: &a, length: Int(kSizeofMFSFSMParameters))
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.fsmParameters, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func observeIA() {
        // uses notify
    }
    
    private func turnOnLED() {
        var a: UInt8 = UInt8(1)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
    
    private func turnOffLED() {
        var a: UInt8 = UInt8(0)
        let data = NSData.init(bytes: &a, length: UInt8.bitWidth)
        spinner.startAnimating()
        peripheral.writeValue(Data.init(referencing: data), for: DeviceCharacteristic.LED, type: CBCharacteristicWriteType.withResponse).subscribe(onSuccess: { (char) in
            print("!!! success write \(String(describing: char.characteristic.value?.hexadecimalString))")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }) { (error) in
            print("!!!! error writing \(data) with error: \(error)")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            }.disposed(by: disposeBag)
    }
}

extension PeripheralInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tag == 2 ? ds2.count : ds.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PeripheralInfoCell
        
        if let aCell = tableView.dequeueReusableCell(withIdentifier: String(describing: PeripheralInfoCell.self)) as? PeripheralInfoCell {
            cell = aCell
        } else {
            cell = PeripheralInfoCell()
        }
        if tableView.tag == 2 {
            cell.config(with: ds2[indexPath.row])
            cell.contentView.backgroundColor = #colorLiteral(red: 0.7476140857, green: 0.8137667775, blue: 0.9230543971, alpha: 1)
        } else {
            cell.config(with: ds[indexPath.row])
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            writeFastConnectionParameters()
        case 1:
            writeFSMParameters()
        case 2:
            writeFindMonitorParameters()
        case 3:
            decommission()
        case 4:
            turnCardOff()
        case 5:
            turnOnLED()
        case 6:
            turnOffLED()
        default:
            break
        }
    }
}
