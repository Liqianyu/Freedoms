//
//  HomePresenter.swift
//  Potatso
//
//  Created by LEI on 6/22/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import Async
protocol HomePresenterProtocol: class {
    func handleRefreshUI()
}

class HomePresenter: NSObject {
    
    var proxies: [Proxy?] = []
    var ruleSets: [RuleSet?] = []
    
    var vc: UIViewController!
    
    var group: ConfigurationGroup {
        return CurrentGroupManager.shared.group
    }
    
    var proxy: Proxy? {
        return group.proxies.first
    }
    
    weak var delegate: HomePresenterProtocol?
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onVPNStatusChanged), name: kProxyServiceVPNStatusNotification, object: nil)
        CurrentGroupManager.shared.onChange = { group in
            self.delegate?.handleRefreshUI()
        }
    }
    
    func bindToVC(vc: UIViewController) {
        self.vc = vc
    }
    
    func importConfigFromUrl() {
        let importer = Importer(vc:self.vc)
        importer.importConfigFromUrl()
    }
    
    func importConfigFromQRCode() {
        let importer = Importer(vc: self.vc)
        importer.importConfigFromQRCode()
    }
    
    func refreshCurrentProxy()
    {
        proxies = defaultRealm.objects(Proxy).sorted("createAt").map({ $0 })
        
        if proxies.count<=0 {
            return
        }
        do {
            try defaultRealm.write {
                self.group.proxies.removeAll()
                
                if let proxy = proxies[proxies.count-1] {
                    self.group.proxies.append(proxy)
                }
            }
            self.delegate?.handleRefreshUI()
        }catch {
            self.vc.showTextHUD("\("Fail to add ruleset".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
        }
        
    }

    func refreshCurrentRule()
    {
        ruleSets = defaultRealm.objects(RuleSet).sorted("createAt").map({ $0 })
        
        if(ruleSets.count>0)
        {
            self.appendRuleSet(ruleSets[ruleSets.count-1])
        }
    }
    
    // MARK: - Actions
    
    func switchVPN() {
        VPN.switchVPN(group) { [unowned self] (error) in
            if let error = error {
                Alert.show(self.vc, message: "\("Fail to switch VPN.".localized()) (\(error))")
            }
        }
    }
    
    func  updateVPN() {
        VPN.updateVPN(group) { [unowned self] (error) in
            
            Async.main(after: 1) {
                self.switchVPN()
            }
            
            if let error = error {
                Alert.show(self.vc, message: "\("Fail to switch VPN.".localized()) (\(error))")
            }
          
        }
    }
    
    func showRuleSetConfiguration(ruleSet: RuleSet?) {
        let ruleSetVC = RuleSetConfigurationViewController(ruleSet: ruleSet)
        vc.navigationController?.pushViewController(ruleSetVC, animated: true)
    }
    
    func chooseProxy() {
        let chooseVC = ProxyListViewController(allowNone: true) { [unowned self] proxy in
            do {
                try defaultRealm.write {
                    self.group.proxies.removeAll()
                    if let proxy = proxy {
                        self.group.proxies.append(proxy)
                    }
                }
                self.delegate?.handleRefreshUI()
            }catch {
                self.vc.showTextHUD("\("Fail to add ruleset".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
        vc.navigationController?.pushViewController(chooseVC, animated: true)
    }
    
    func chooseConfigGroups() {
        ConfigGroupChooseManager.shared.show()
    }
    
    func showAddConfigGroup() {
        var urlTextField: UITextField?
        let alert = UIAlertController(title: "Add Config Group".localized(), message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Name".localized()
            urlTextField = textField
        }
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .Default, handler: { (action) in
            if let input = urlTextField?.text {
                do {
                    try self.addEmptyConfigGroup(input)
                }catch{
                    Alert.show(self.vc, message: "\("Failed to add config group".localized()): \(error)")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .Cancel, handler: nil))
        vc.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addEmptyConfigGroup(name: String) throws {
        let trimmedName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if trimmedName.characters.count == 0 {
            throw "Name can't be empty".localized()
        }
        if let _ = defaultRealm.objects(ConfigurationGroup).filter("name = '\(trimmedName)'").first {
            throw "Name already exists".localized()
        }
        let group = ConfigurationGroup()
        group.name = trimmedName
        try defaultRealm.write {
            defaultRealm.add(group)
        }
        CurrentGroupManager.shared.group = group
    }
    
    func addRuleSet() {
        let destVC: UIViewController
        if defaultRealm.objects(RuleSet).count == 0 {
            destVC = RuleSetConfigurationViewController() { [unowned self] ruleSet in
                self.appendRuleSet(ruleSet)
            }
        }else {
            destVC = RuleSetListViewController { [unowned self] ruleSet in
                self.appendRuleSet(ruleSet)
            }
        }
        vc.navigationController?.pushViewController(destVC, animated: true)
    }
    
    func appendRuleSet(ruleSet: RuleSet?) {
        guard let ruleSet = ruleSet where !group.ruleSets.contains(ruleSet) else {
            return
        }
        do {
            try defaultRealm.write {
                group.ruleSets.append(ruleSet)
            }
            self.delegate?.handleRefreshUI()
        }catch {
            self.vc.showTextHUD("\("Fail to add ruleset".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
        }
    }
    
    func updateDNS(dnsString: String) {
        var dns: String = ""
        let trimmedDNSString = dnsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if trimmedDNSString.characters.count > 0 {
            let dnsArray = dnsString.componentsSeparatedByString(",").map({ $0.componentsSeparatedByString("，") }).flatMap({ $0 }).map({ $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())}).filter({ $0.characters.count > 0 })
            let ipRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$";
            guard let regex = try? Regex(ipRegex) else {
                fatalError()
            }
            let valids = dnsArray.map({ regex.test($0) })
            let valid = valids.reduce(true, combine: { $0 && $1 })
            if !valid {
                dns = ""
                Alert.show(self.vc, title: "Invalid DNS".localized(), message: "DNS should be valid ip addresses (separated by commas if multiple). e.g.: 8.8.8.8,8.8.4.4".localized())
            }else {
                dns = dnsArray.joinWithSeparator(",")
            }
        }
        do {
            try defaultRealm.write {
                self.group.dns = dns
            }
        }catch {
            self.vc.showTextHUD("\("Fail to change dns".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
        }
    }
    
    func onVPNStatusChanged() {
        self.delegate?.handleRefreshUI()
    }
    
}

class CurrentGroupManager {
    
    static let shared = CurrentGroupManager()
    
    private init() {}
    
    var onChange: (ConfigurationGroup? -> Void)?
    
    var group: ConfigurationGroup! {
        didSet(o) {
            self.onChange?(group)
        }
    }
    
}