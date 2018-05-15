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
        addSubview(title)
        
        spinner.snp.makeConstraints { (make) in
            make.size.equalTo(30)
            make.center.equalToSuperview()
        }
        title.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    func shouldShowConnected(_ connected: Bool) {
        if connected {
            spinner.stopAnimating()
        }
        spinner.isHidden = connected
        title.isHidden = !connected
        if connected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isHidden = true
            }
        }

    }
}
