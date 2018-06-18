//
//  ViewController.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import RxBluetoothKit
import CoreBluetooth
import SnapKit
import RealmSwift

class ViewController: UIViewController {
  private let disposeBag = DisposeBag()
  
  private let vm: DashboardViewModel = DashboardViewModel()
  
  private var isReadingInfo: Bool = false
  
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
    spinner.hidesWhenStopped = true
    return spinner
  }()
  private lazy var debugLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    label.textColor = UIColor.gray
    label.textAlignment = .left
    label.numberOfLines = 0
    return label
    
  }()
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    startObservingViewModel()
    vm.bind()
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
    view.addSubview(debugLabel)
    
    spinner.isHidden = false
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
      make.left.right.equalToSuperview()
      make.top.equalTo(sectionSeparator.snp.bottom).offset(1)
      make.bottom.equalTo(debugLabel.snp.top)
    }
    debugLabel.snp.makeConstraints { (make) in
      make.left.right.bottom.equalToSuperview()
      make.height.equalTo(44)
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
  private func startObservingViewModel() {
    vm.scanningError.subscribe { [weak self] (event) in
      if let result = event.element {
        switch result {
        case .success(_):
          self?.stopLoading()
          break
        case .error(let error):
          self?.scanningHelperView.updateSubtitle(to: "\(error)")
          DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { // jsut to have the error on screen for 1 sec
            self?.stopLoading()
          })
        }
      }
      }.disposed(by: disposeBag)
    
    vm.dataUpdatedObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(_):
        self?.reloadTableViewOnMainThread()
      case .error(_):
        self?.stopLoading()
      }
    }, onError: { [weak self] (error) in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.startCardBindingObserver.subscribe(onNext: { [weak self] (result) in
      self?.scanningHelperView.isHidden = false
      self?.scanningHelperView.updateSubtitle(to: "Started card binding flow")
    }, onError: { [weak self] (error) in
      self?.stopLoading()
    }, onCompleted: { [weak self] in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.reconnectionObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(_):
        self?.reloadTableViewOnMainThread()
      case .error(let error):
        let alert = UIAlertController.init(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
        self?.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
          alert.dismiss(animated: true, completion: nil)
        })
        self?.stopLoading()
      }
    }, onError: { [weak self] (error) in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.reConnectingInProgressObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let inProgress):
        if inProgress {
          self?.spinner.stopAnimating()
          self?.scanningHelperView.isHidden = false
          self?.scanningHelperView.updateSubtitle(to: "Re-Connecting...")
        }

      case .error(_):
        self?.stopLoading()
      }
    }, onError: { [weak self] (error) in
      self?.stopLoading()
    }, onCompleted: { [weak self] in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.disconnectObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let peripheral):
        self?.vm.disconnect(peripheral)
        self?.reloadTableViewOnMainThread()
      case .error(_):
        self?.stopLoading()
      }
    }, onError: { [weak self] (error) in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.readingCardObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let isReading): // TODO: consider using onCompleted and remove `isReading`
        DispatchQueue.main.async {
          self?.scanningHelperView.isHidden = !isReading
          self?.isReadingInfo = isReading
          if isReading {
            self?.scanningHelperView.updateSubtitle(to: "reading card data...")
          }
        }
      case .error(_):
        self?.stopLoading()
        break
      }
    }, onError: { [weak self] (_) in
      self?.stopLoading()
    }).disposed(by: disposeBag)
    
    vm.unlinkCardObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let success):
        if success {
          DispatchQueue.main.async {
            self?.scanningHelperView.isHidden = true
          }
        }
      case .error(_):
        DispatchQueue.main.async {
          self?.scanningHelperView.isHidden = true
        }
      }
    }, onError: { [weak self] (error) in
      DispatchQueue.main.async {
        self?.scanningHelperView.isHidden = true
      }
    }).disposed(by: disposeBag)
    
    vm.turnOffCardObserver.subscribe(onNext: { [weak self] (result) in
      switch result {
      case .success(let success):
        if success {
          DispatchQueue.main.async {
            self?.scanningHelperView.isHidden = true
          }
        }
      case .error(_):
        DispatchQueue.main.async {
          self?.scanningHelperView.isHidden = true
        }
      }
    }, onError: { [weak self] (error) in
      DispatchQueue.main.async {
        self?.scanningHelperView.isHidden = true
      }
    }).disposed(by: disposeBag)
    
    vm.debugObserver.subscribe(onNext: { (result) in
      switch result {
      case .success(let str):
        DispatchQueue.main.async {
            self.debugLabel.text = str
        }
        
      default:
        break
      }
    }).disposed(by: disposeBag)
  }
  private func stopLoading() {
    DispatchQueue.main.async {
      self.spinner.stopAnimating()
      self.scanningHelperView.isHidden = !self.isReadingInfo
    }
  }
  private func reloadTableViewOnMainThread() {
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  @objc func startScanning() {
    vm.startScanning()
    scanningHelperView.isHidden = false
    scanningHelperView.shouldShowConnected(false)
    scanningHelperView.updateSubtitle(to: "Scanning...")
  }
}
extension ViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vm.numberOfItems()
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: CardCell
    if let aCell = tableView.dequeueReusableCell(withIdentifier: String(describing: CardCell.self)) as? CardCell {
      cell = aCell
    } else {
      cell = CardCell()
    }
    if let model = vm.item(at: indexPath) {
      cell.config(with: model)
    }
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
    let disconnect = UITableViewRowAction(style: .destructive, title: "Unlink") { (action, indexPath) in
      self.vm.unlink(at: indexPath)
      self.scanningHelperView.isHidden = false
      self.scanningHelperView.updateSubtitle(to: "Unlinking...")
      tableView.reloadData()
    }
    let turnOff = UITableViewRowAction(style: .normal, title: "Turn Off") { (action, indexPath) in
      self.vm.turnOff(at: indexPath)
      self.scanningHelperView.isHidden = false
      self.scanningHelperView.updateSubtitle(to: "Turning Off...")
      tableView.reloadData()
    }
    return [disconnect, turnOff]
    
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let monitor = vm.item(at: indexPath) else { return }
    let vc = PeripheralInfoViewController()
    vc.vm = PeripheralInfoViewModel.init(with: monitor)
    if monitor.realmCard.isConnected && monitor.realmCard.isOn {
      navigationController?.pushViewController(vc, animated: true)
    }
  }
}
