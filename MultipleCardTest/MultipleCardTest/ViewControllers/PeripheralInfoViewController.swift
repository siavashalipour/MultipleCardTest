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
    
    var vm: PeripheralInfoViewModel! {
        didSet {
            tableView.reloadData()
        }
    }
    var ds2: [PeripheralInfoCellData] = [
        PeripheralInfoCellData(title: "writeFastConnectionParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kFastConnectionParameters, length: Int(Constant.PackageSizes.kSizeofMFSConnectionParameters)))"),
        PeripheralInfoCellData(title: "writeFSMParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kDefaultFSMParameters, length: Int(Constant.PackageSizes.kSizeofMFSFSMParameters)))"),
        PeripheralInfoCellData(title: "writeFindMonitorParameters",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kMFSFindMonitorParameters, length: Int(Constant.PackageSizes.kSizeofMFSFindMonitorParameters)))"),
        PeripheralInfoCellData(title: "decommission",
                               subtitle: "\(NSData.init(bytes: &CardParameters.kDecommissionFSMParameters, length: Int(Constant.PackageSizes.kSizeofMFSFSMParameters)))"),
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
        view.isHidden = true
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
}

extension PeripheralInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tag == 2 ? ds2.count : vm.numberOfItems()
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
            if let item = vm.item(at: indexPath) {
                cell.config(with: item)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch indexPath.row {
//        case 0:
//            writeFastConnectionParameters()
//        case 1:
//            writeFSMParameters()
//        case 2:
//            writeFindMonitorParameters()
//        case 3:
//            decommission()
//        case 4:
//            turnCardOff()
//        case 5:
//            turnOnLED()
//        case 6:
//            turnOffLED()
//        default:
//            break
//        }
    }
}
