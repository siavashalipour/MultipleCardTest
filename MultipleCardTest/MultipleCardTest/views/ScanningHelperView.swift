//
//  ScanningHelperView.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import UIKit

final class ScanningHelperView: UIView {
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        spinner.startAnimating()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    private lazy var subtitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.dark
        label.textAlignment = .center
        label.text = ""
        label.isHidden = true
        return label
    }()
    
    private lazy var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.cellTitle
        label.textColor = UIColor.dark
        label.textAlignment = .center
        label.text = "Connected"
        label.isHidden = true
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupUI() {
        _ = subviews.map({$0.removeFromSuperview()})
        layer.cornerRadius = 4
        addSubview(spinner)
        addSubview(subtitle)
        addSubview(title)
        
        spinner.snp.makeConstraints { (make) in
            make.size.equalTo(30)
            make.center.equalToSuperview()
        }
        subtitle.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(spinner.snp.bottom).offset(8)
        }
        title.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    func shouldShowConnected(_ connected: Bool) {
        DispatchQueue.main.async {
            if connected {
                self.spinner.stopAnimating()
            } else {
                self.spinner.startAnimating()
            }
            self.spinner.isHidden = connected
            self.title.isHidden = !connected
            self.subtitle.isHidden = connected
            if connected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isHidden = true
                }
            }
        }
    }
    func updateSubtitle(to text: String) {
        DispatchQueue.main.async {
            self.spinner.isHidden = false
            self.subtitle.text = text
            self.subtitle.isHidden = false
        }
    }
}
