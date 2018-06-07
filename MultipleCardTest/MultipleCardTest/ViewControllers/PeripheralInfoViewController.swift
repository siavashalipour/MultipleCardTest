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
    
    private let disposeBag = DisposeBag()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PeripheralInfoCell.self, forCellReuseIdentifier: String(describing: PeripheralInfoCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = nil
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 60
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
    private lazy var updateBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Update", for: .normal)
        btn.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        btn.layer.cornerRadius = 5
        return btn
    }()
    private lazy var progressTxt: UITextField = {
        let txt = UITextField()
        txt.textAlignment = .center
        txt.textColor = .black
        
        return txt
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    private func bind() {
        vm.bind(updateBtn: updateBtn.rx.tap.asObservable())
        vm.shouldHideUpdateButtonObserver
            .bind(to: updateBtn.rx.isHidden)
            .disposed(by: disposeBag)
        vm.shouldHideUpdateButtonObserver
            .bind(to: progressTxt.rx.isHidden)
            .disposed(by: disposeBag)
        vm.shouldReloadDataObserver.subscribe { (_) in
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        vm.progressText.asObservable().bind(to: progressTxt.rx.text).disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(scanningHelperView)
        view.addSubview(updateBtn)
        view.addSubview(progressTxt)
        
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height/2)
        }
        scanningHelperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 220, height: 160))
        }
        
        updateBtn.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.left.equalTo(16)
            make.centerX.equalToSuperview()
            make.top.equalTo(tableView.snp.bottom).offset(10)
        }
        progressTxt.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerX.equalToSuperview()
            make.top.equalTo(updateBtn.snp.bottom).offset(4)
        }
    }
}

extension PeripheralInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.numberOfItems()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PeripheralInfoCell
        
        if let aCell = tableView.dequeueReusableCell(withIdentifier: String(describing: PeripheralInfoCell.self)) as? PeripheralInfoCell {
            cell = aCell
        } else {
            cell = PeripheralInfoCell()
        }
        if let item = vm.item(at: indexPath) {
            cell.config(with: item)
        }
        return cell
    }
}
