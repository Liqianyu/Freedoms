//
//  CurrentGroupCell.swift
//  Potatso
//
//  Created by LEI on 4/13/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import Cartography
import PotatsoLibrary

class CurrentGroupCell: UITableViewCell {
    
    var switchVPN: (()->Void)?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        contentView.addSubview(switchButton)
        setupLayout()
    }
    
    func onSwitchValueChanged() {
        switchVPN?()
    }
    
    func config(name: String?, status: Bool, switchVPN: (() -> Void)?) {
        nameLabel.text = name ?? "None".localized()
        switchButton.addTarget(self, action: #selector(self.onSwitchValueChanged), forControlEvents:.ValueChanged)
        
        switchButton.setOn(status,animated: false)
        
        self.switchVPN = switchVPN
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        constrain(nameLabel, switchButton, contentView) { nameLabel, switchButton, superView in
            nameLabel.leading == superView.leading
            nameLabel.centerY == superView.centerY
            nameLabel.trailing == switchButton.leading - 10
            
            switchButton.centerY == superView.centerY
            switchButton.trailing == superView.trailing
            switchButton.width == 70
            switchButton.height == 30
        }
    }
    
    lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.boldSystemFontOfSize(17)
        v.textColor = UIColor.whiteColor()
        return v
    }()
    
    lazy var switchButton: UISwitch = {
        
        let v = UISwitch()
        
        return v
    }()
    
}