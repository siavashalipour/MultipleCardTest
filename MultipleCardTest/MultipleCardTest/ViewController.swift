//
//  ViewController.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxBluetoothKit
import CoreBluetooth
import SnapKit
import RealmSwift

class ViewController: UIViewController {

    let manager = CentralManager(queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "some.unique.key" as AnyObject])
    let kRSSIThreshold: Double = -60
    private var scanningDisposable: Disposable?
    private var peripheralDisposable: Disposable!
    
    private var isScanning: Bool = false
    private var peripheralConnections: [String: Disposable] = [:]
    
    private lazy var settingBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(#imageLiteral(resourceName: "iconSettings"), for: .normal)
        btn.addTarget(self, action: #selector(showSetting), for: .touchUpInside)
        return btn
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32.0, weight: .bold)
        label.textAlignment = .left
        label.text = "Safedome"
        label.textColor = UIColor.dark
        return label
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.gray
        label.text = "MONITORS CONNECTED".uppercased()
        label.textAlignment = .left
        return label
    }()
    private lazy var sectionSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9607843137, alpha: 1)
        return view
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CardCell.self, forCellReuseIdentifier: String(describing: CardCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = nil
        tableView.separatorStyle = .none
        return tableView
    }()
    private lazy var scanningHelperView: ScanningHelperView = {
        let view = ScanningHelperView()
        view.backgroundColor = #colorLiteral(red: 0.7476140857, green: 0.8137667775, blue: 0.9230543971, alpha: 1)
        view.isHidden = true
        return view
    }()
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        spinner.startAnimating()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    private var ds: [CardModel] = [] {
        didSet {
            applicationWillTerminate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        setupUI()
        setupDS()
        reconnect()
        spinner.startAnimating()
    }
    private func setupUI() {
        view.addSubview(settingBtn)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(sectionSeparator)
        view.addSubview(tableView)
        view.addSubview(scanningHelperView)
        view.addSubview(spinner)
        
        settingBtn.snp.makeConstraints { (make) in
            make.size.equalTo(28)
            make.right.equalTo(-22)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.top.equalTo(settingBtn.snp.centerY)
        }
        subtitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        sectionSeparator.snp.makeConstraints { (make) in
            make.height.equalTo(2)
            make.left.right.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(14)
        }
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(sectionSeparator.snp.bottom).offset(1)
        }
        scanningHelperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 220, height: 160))
        }
        spinner.snp.makeConstraints { (make) in
            make.size.equalTo(30)
            make.center.equalToSuperview()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func showSetting() {

    }
    @objc func startScanning() {
        scanningHelperView.isHidden = false
        scanningHelperView.shouldShowConnected(false)
        if isScanning {
            if let scanningDisposable = scanningDisposable {
                scanningDisposable.dispose()
            }
        }
        self.scanningDisposable = self.manager.scanForPeripherals(withServices: nil)
            .subscribe(onNext: { (scanned) in
                //Sends through the first MFSCardPeripheral that advertises due to button press with RSSI > kRSSIThreshold
                let shouldConnect = scanned.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String == "safedome" && scanned.rssi.doubleValue > self.kRSSIThreshold
                if shouldConnect && scanned.peripheral.state != CBPeripheralState.connected {
                    self.peripheralDisposable = scanned.peripheral.establishConnection().take(1).timeout(40, scheduler: MainScheduler.asyncInstance)
                        .subscribe(onNext: { (peripheral) in
                            print("Connected to: \(peripheral)")
                            self.scanningHelperView.shouldShowConnected(true)
                            self.add(peripheral: scanned.peripheral)
                        }, onError: { (error) in
                            print("!!! error: \(error)")
                            self.scanningHelperView.shouldShowConnected(true)
                        })
                }
                
            })
        
        isScanning = !isScanning
    }
    private func reconnect() {
        _ = manager.observeState().subscribe(onNext: { (state) in
            switch state {
            case .poweredOn:
                self.establishConnections()
                self.isScanning = true
            default:
                break
            }
        })

    }
    private func establishConnections() {
        if let uuidStrings: [String] = UserDefaults.standard.array(forKey: Constant.Strings.uuidsKey) as? [String] {
            if uuidStrings.count == 0 {
                spinner.stopAnimating()
                return
            }
            var uuids: [UUID] = []
            for uuid in uuidStrings {
                if let aUUID = UUID.init(uuidString: uuid) {
                    uuids.append(aUUID)
                }
            }

            let peripherals = manager.retrievePeripherals(withIdentifiers: uuids)
            var connection: [Disposable] = []
            for peripheral in peripherals {
                 let aConnection = peripheral.establishConnection()
                    .timeout(30, scheduler: MainScheduler.asyncInstance)
                    .subscribe(onNext: { (peripheral) in
                        print("reConnected to: \(peripheral)")
                        self.scanningHelperView.shouldShowConnected(true)
                        self.add(peripheral: peripheral)
                        self.spinner.stopAnimating()
                    }, onError: { (error) in
                        print("!!! \(error)")
                        self.spinner.stopAnimating()
                    }, onCompleted: {
                        print("!!! Done")
                    })
                connection.append(aConnection)
            }
//            _ = connection.map({
//                $0.dispose()
//            })
        } else {
            spinner.stopAnimating()
        }
    }
    private func add(peripheral: Peripheral?) {
        let card = CardModel(cardName: "safedome", uuid: "\(peripheral!.identifier)", isConnected: true, peripheral: peripheral)
        if !ds.contains(where: {
            $0.uuid == card.uuid
        }) {
            ds.append(card)
        }
        tableView.reloadData()
//        scanningDisposable?.dispose()
    }
    private func setupDS() {
        // Query and update from any thread
        self.tableView.reloadData()
    }
}
// MARK: - notification
extension ViewController {
    @objc func applicationWillTerminate() {
        // save the current connected UUIDs
        let uuids: [String] = ds.map({$0.uuid})
        UserDefaults.standard.set(uuids, forKey: Constant.Strings.uuidsKey)
    }
}
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ds.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CardCell
        if let aCell = tableView.dequeueReusableCell(withIdentifier: String(describing: CardCell.self)) as? CardCell {
            cell = aCell
        } else {
            cell = CardCell()
        }
        cell.config(with: ds[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        let btn = UIButton()
        btn.setTitle("+", for: .normal)
        btn.setAttributedTitle(NSAttributedString(string: "+", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24, weight: .bold), NSAttributedStringKey.foregroundColor: UIColor.secondary]), for: .normal)
        btn.addTarget(self, action: #selector(startScanning), for: .touchUpInside)
        view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return view
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let disconnect = UITableViewRowAction(style: .default, title: "Disconnect") { (action, indexPath) in
            // share item at indexPath

            if indexPath.row > self.ds.count {
                return
            }
            let uuid = "\(self.ds[indexPath.row].uuid)"
            
            self.manager.centralManager.cancelPeripheralConnection(self.ds[indexPath.row].peripheral!.peripheral)
            self.ds.remove(at: indexPath.row)
            tableView.reloadData()
            self.peripheralDisposable?.dispose()
            guard let disposable = self.peripheralConnections[uuid] else {
                return
            }
            disposable.dispose()
            self.peripheralConnections[uuid] = nil
            
        }
        
        return [disconnect]
        
    }
}
