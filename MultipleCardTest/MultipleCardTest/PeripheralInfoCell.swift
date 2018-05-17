//
//  PeripheralInfoCell.swift
//  MultipleCardTest
//
//  Created by Siavash on 16/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import UIKit
import SnapKit


class PeripheralInfoCell: UITableViewCell {
    
    private lazy var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()
    private lazy var subtitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupUI() {
        
        _ = contentView.subviews.map({$0.removeFromSuperview()})
        
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        
        title.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(6)
        }
        subtitle.snp.makeConstraints { (make) in
            make.left.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }
    }
    
    func config(with data: PeripheralInfoCellData) {
        title.text = data.title
        subtitle.text = data.subtitle
    }
}

struct PeripheralInfoCellData {
    let title: String
    let subtitle: String
}
