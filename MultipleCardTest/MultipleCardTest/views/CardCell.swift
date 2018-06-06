//
//  CardCell.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import UIKit

final class CardCell: UITableViewCell {
    
    private lazy var imageBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.primary
        view.layer.cornerRadius = 25
        return view
    }()
    private lazy var cardImage: UIImageView = {
        let imgView = UIImageView.init(image: #imageLiteral(resourceName: "iconMonitorBackpack"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    private lazy var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.numberOfLines = 0 
        label.textColor = UIColor.dark 
        return label
    }()
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9607843137, alpha: 1)
        return view
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    private func setupUI() {
        _ = contentView.subviews.map({$0.removeFromSuperview()})
        
        contentView.addSubview(imageBgView)
        contentView.addSubview(cardImage)
        contentView.addSubview(title)
        contentView.addSubview(separator)
        
        
        imageBgView.snp.makeConstraints { (make) in
            make.size.equalTo(50)
            make.centerY.equalToSuperview()
            make.left.equalTo(20)
            make.top.equalTo(35)
        }
        cardImage.snp.makeConstraints { (make) in
            make.center.equalTo(imageBgView)
            make.size.equalTo(38)
        }
        title.snp.makeConstraints { (make) in
            make.left.equalTo(imageBgView.snp.right).offset(15)
            make.centerY.equalTo(imageBgView)
        }
        separator.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.height.equalTo(2)
            make.left.equalTo(20)
        }
    }
    
    func config(with data: Monitor) {
        title.text = "\(data.realmCard.uuid)"
    }
}
