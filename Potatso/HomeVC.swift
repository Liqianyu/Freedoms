//
//  IndexViewController.swift
//  Potatso
//
//  Created by LEI on 5/27/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoLibrary
import PotatsoModel
import Eureka
import ICDMaterialActivityIndicatorView
import Cartography

private let kFormName = "name"
private let kFormDNS = "dns"
private let kFormProxies = "proxies"
private let kFormDefaultToProxy = "defaultToProxy"

class HomeVC: FormViewController, UINavigationControllerDelegate, HomePresenterProtocol, UITextFieldDelegate {
    
    let presenter = HomePresenter()
    
    var ruleSetSection: Section!
    
    var startSection: Section!
    
    var proxies: [Proxy?] = []
    
    var row: AnyObject!
    
    var status: VPNStatus {
        didSet(o) {
            connectButton.enabled = [VPNStatus.On, VPNStatus.Off].contains(status)
            connectButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            switch status {
            case .Connecting, .Disconnecting:
                connectButton.animating = true
            default:
                connectButton.setTitle(status.hintDescription, forState: .Normal)
                connectButton.animating = false
            }
            connectButton.backgroundColor = status.color
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.status = .Off
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        presenter.bindToVC(self)
        presenter.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fix a UI stuck bug
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Post an empty message so we could attach to packet tunnel process
        Manager.sharedManager.postMessage()
        handleRefreshUI()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: "ScanQR".templateImage, style: .Plain, target: presenter, action: #selector(presenter.importConfigFromQRCode))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: presenter, action: #selector(presenter.importConfigFromUrl))
        
    }
    
    // MARK: - HomePresenter Protocol
    
    func handleRefreshUI() {
        if presenter.group.isDefault {
            status = Manager.sharedManager.vpnStatus
        }else {
            status = .Off
        }
        updateTitle()
        updateForm()
    }
    
    func updateTitle() {
        navigationItem.title = "Freedoms"
    }
    
    func updateForm() {
        form.delegate = nil
        form.removeAll()
        form +++ generateStartSection()
        form +++ generateProxySection()
        form +++ generateRuleSetSection()
        form.delegate = self
        tableView?.reloadData()
    }
    
    
    func showRuleSetConfiguration(ruleSet: RuleSet?) {
        let vc = RuleSetConfigurationViewController(ruleSet: ruleSet)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Form
    
    // start button section
    func generateStartSection() -> Section {
        
        startSection = Section("Connect Status".localized())
        
        startSection <<< SwitchRow() {
            
            switch self.status {
                
            case .Connecting:
                $0.title = "Connecting".localized()
                $0.value = true
                break;
            case .Disconnecting:
                $0.title = "Stoping".localized()
                break;
            case .On:
                $0.title = "Connected".localized()
                $0.value = true
                break;
            case .Off:
                $0.title = "Closed".localized()
                $0.value = false
                break;
            }
            
            }.onChange({ [unowned self] (row) in
                self.switchVPN()
                })
        
        return startSection
    }
    
    func generateProxySection() -> Section {
        
        let proxySection = Section("Current Proxy".localized())
        
        proxySection <<< SwitchRow(kFormDefaultToProxy) {
            
            $0.title = "Global Mode".localized()
            $0.value = presenter.group.defaultToProxy
            $0.hidden = Condition.Function([kFormProxies]) { [unowned self] form in
                return self.presenter.proxy == nil
            }
            }.onChange({ [unowned self] (row) in
                do {
                    try defaultRealm.write {
                        self.presenter.group.defaultToProxy = row.value ?? true
                    }
                    self.updateVPN()
                    
                }catch {
                    self.showTextHUD("\("Fail to modify global mode".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
                }
                
                })
        
        if let proxy = presenter.proxy {
            proxySection <<< ProxyRow(kFormProxies) {
                $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .DisclosureIndicator
                    cell.selectionStyle = .Default
                    cell.detailButton.hidden = true;
                    
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.presenter.chooseProxy()
                    })
        }else {
            proxySection <<< LabelRow() {
                $0.title = "Proxy".localized()
                $0.value = "None".localized()
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .DisclosureIndicator
                    cell.selectionStyle = .Default
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.presenter.chooseProxy()
                    })
        }
        
        //        <<< TextRow(kFormDNS) {
        //            $0.title = "DNS".localized()
        //            $0.value = presenter.group.dns
        //        }.cellSetup { cell, row in
        //            cell.textField.placeholder = "System DNS".localized()
        //        }
        return proxySection
    }
    
    func generateRuleSetSection() -> Section {
        ruleSetSection = Section("Rule Set".localized())
        for ruleSet in presenter.group.ruleSets {
            ruleSetSection
                <<< LabelRow () {
                    $0.title = "\(ruleSet.name)"
                    $0.value = ruleSet.rules.count <= 1 ? String(format: "%d rules".localized(), ruleSet.rules.count) :  String(format: "%d rule".localized(), ruleSet.rules.count)
                    }.cellSetup({ (cell, row) -> () in
                        cell.accessoryType = .DisclosureIndicator
                        cell.selectionStyle = .Default
                    }).onCellSelection({ [unowned self](cell, row) -> () in
                        cell.setSelected(false, animated: true)
                        self.presenter.addRuleSet()
                        })
        }
        ruleSetSection <<< BaseButtonRow () {
            
            $0.title = "Add Rule Set".localized()
            
            if presenter.group.ruleSets.count > 0
            {
                $0.hidden = true
                
            }else
            {
                $0.hidden = false
            }
            
            }.onCellSelection({ [unowned self] (cell, row) -> () in
                self.presenter.addRuleSet()
                })
        return ruleSetSection
    }
    
    
    // MARK: - Private Actions
    
    func updateVPN() {
        presenter.updateVPN()
    }
    
    func switchVPN() {
        if status == .On {
            status = .Disconnecting
        }else {
            status = .Connecting
        }
        presenter.switchVPN()
    }
    
    // MARK: - TableView
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == ruleSetSection.index && indexPath.row < presenter.group.ruleSets.count {
            return true
        }
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do {
                try defaultRealm.write {
                    presenter.group.ruleSets.removeAtIndex(indexPath.row)
                }
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
                handleRefreshUI()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    // MARK: - TextRow
    
    override func textInputDidEndEditing<T>(textInput: UITextInput, cell: Cell<T>) {
        guard let textField = textInput as? UITextField, dnsString = textField.text where cell.row.tag == kFormDNS else {
            return
        }
        presenter.updateDNS(dnsString)
        textField.text = presenter.group.dns
    }
    
    // MARK: - View Setup
    
    private let connectButtonHeight: CGFloat = 48
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.Background
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(connectButton)
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, connectButtonHeight, 0)
    }
    
    func setupLayout() {
        constrain(connectButton, view) { connectButton, view in
            connectButton.trailing == view.trailing
            connectButton.leading == view.leading
            connectButton.height == connectButtonHeight
            connectButton.bottom == view.bottom
        }
    }
    
    lazy var connectButton: FlatButton = {
        let v = FlatButton(frame: CGRect.zero)
        v.addTarget(self, action: #selector(switchVPN), forControlEvents: .TouchUpInside)
        return v
    }()
    
}

extension VPNStatus {
    
    var color: UIColor {
        switch self {
        case .On, .Disconnecting:
            return Color.StatusOn
        case .Off, .Connecting:
            return Color.StatusOff
        }
    }
    
    var hintDescription: String {
        switch self {
        case .On, .Disconnecting:
            return "Disconnect".localized()
        case .Off, .Connecting:
            return "Connect".localized()
        }
    }
}