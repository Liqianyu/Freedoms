//
//  ProxyRow.swift
//  Potatso
//
//  Created by LEI on 6/1/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Eureka
import Cartography


protocol ProxyRowProtocol: class {
    func pushUI(proxy: Proxy?)
}

public final class ProxyRow: Row<Proxy, ProxyRowCell>, RowType {
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public class ProxyRowCell: Cell<Proxy>,CellType,SimplePingDelegate {
    
    let group = ConstraintGroup()
    
    let detailButton: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(named:"detailButtonImg"), forState:UIControlState.Normal)
        return v
    }()
    
    weak var delegate: ProxyRowProtocol?
    
    private var pinger: SimplePing?
    private var hostName: String?
    private var sendTimer: NSTimer?
    private var sendDate: NSDate?
    private var receiveDate: NSDate?
    private var timeoutTimer: NSTimer?
    
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public override func setup() {
        super.setup()
        preservesSuperviewLayoutMargins = false
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsZero
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(detailButton)
        contentView.addSubview(ipLabel)
        contentView.addSubview(pingLabel)
    }
    
    
    public override func update() {
        super.update()
        if let proxy = row.value {
            titleLabel.text = proxy.name
            ipLabel.text = proxy.host
            iconImageView.hidden = true
            iconImageView.image = UIImage(named: "ProxysSatus")
            
            let status = Manager.sharedManager.vpnStatus
            switch status {
            case .On:
                pingLabel.hidden = true
                break
            default:
                pingLabel.hidden = false
                beginPingServer(proxy.host);
            }
            
            
        }else {
            titleLabel.text = "None".localized()
            iconImageView.hidden = true
        }
        
        if let proxy = row.value {
            if (CurrentGroupManager.shared.group.proxies.count>0) {
                if  (proxy == CurrentGroupManager.shared.group.proxies[0]) {
                    iconImageView.hidden = false
                }else {
                    iconImageView.hidden = true
                }
            }
            
        }
        
        if row.isDisabled {
            titleLabel.textColor = "5F5F5F".color
            ipLabel.textColor = "5F5F5F".color
            pingLabel.textColor = "5F5F5F".color
        }else {
            titleLabel.textColor = "000".color
            ipLabel.textColor = "B2B2B2".color
            pingLabel.textColor = "B2B2B2".color
        }
        
        let viewArray = [titleLabel, iconImageView,detailButton,ipLabel,contentView,pingLabel];
        
        constrain(viewArray,replace: group) { viewArray in
            
            viewArray[0].top ==  viewArray[4].top + 10
            viewArray[0].centerY == viewArray[4].centerY - 15
            viewArray[0].leading == viewArray[4].leading + 30
            viewArray[0].trailing == viewArray[4].trailing - 16
            
            viewArray[1].leading == viewArray[4].leading + 10
            viewArray[1].width == 10
            viewArray[1].height == 10
            viewArray[1].centerY == viewArray[4].centerY - 15
            
            viewArray[2].centerY == viewArray[4].centerY
            viewArray[2].width == 45
            viewArray[2].height == 45
            viewArray[2].right == viewArray[4].right - 5
            
            viewArray[3].centerY == viewArray[4].centerY + 15
            viewArray[3].leading == viewArray[4].leading + 30
            viewArray[3].trailing == viewArray[4].trailing - 16
            viewArray[3].bottom == viewArray[4].bottom - 10
            
            
            viewArray[5].centerY == viewArray[4].centerY + 15
            viewArray[5].width == 80
            viewArray[5].height == 30
            viewArray[5].bottom == viewArray[4].bottom - 10
            viewArray[5].trailing == viewArray[4].trailing - 60
            
            self.detailButton.addTarget(self, action: #selector(ProxyRowCell.detialButtonAction), forControlEvents: .TouchUpInside)
        }
        
    }
    
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFontOfSize(17)
        return v
    }()
    
    lazy var iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .ScaleAspectFill
        return v
    }()
    
    
    lazy var ipLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFontOfSize(16)
        return v
    }()
    
    
    lazy var pingLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFontOfSize(16)
        v.textAlignment = .Right
        return v
    }()
    
    func detialButtonAction(){
        let proxy = row.value
        self.showProxyConfiguration(proxy)
    }
    
    func showProxyConfiguration(proxy: Proxy?) {
        self.delegate?.pushUI(proxy)
    }
    
    
    //MARK: ping Delegate
    
    func beginPingServer(host:String)
    {
        let pinger = SimplePing(hostName:host)
        
        if  (host.rangeOfString(":")?.startIndex) != nil
        {
            pinger.addressStyle = .ICMPv6
            
        }else
        {
            pinger.addressStyle = .ICMPv4
        }
        
        self.pinger = pinger
        pinger.delegate = self
        pinger.start()
    }
    
    func stopPing() {
        NSLog("stop")
        self.pinger?.stop()
        self.pinger = nil
        self.sendTimer?.invalidate()
        self.sendTimer = nil
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    func sendPing() {
        
        if let pinger  = pinger {
            pinger.sendPingWithData(nil)
        }
    }
    
    func checkIfTimeOut(sender: AnyObject?) {
        stopPing()
        guard receiveDate != nil else {
            pingLabel.text  = "timeout!"
            pingLabel.textColor = "DF1921".color
            return
        }
    }
    
    
    // MARK: pinger delegate callback
    
    public func simplePing(pinger: SimplePing, didStartWithAddress address: NSData) {
        self.sendPing()
        self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(sendPing), userInfo: nil, repeats: true)
        self.timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ProxyRowCell.checkIfTimeOut), userInfo:nil, repeats: false)
    }
    
    public func simplePing(pinger: SimplePing, didFailWithError error: NSError) {
        self.stopPing()
    }
    
    
    public func simplePing(pinger: SimplePing, didSendPacket packet: NSData, sequenceNumber: UInt16) {
        sendDate = NSDate()
    }
    
    public func simplePing(pinger: SimplePing, didFailToSendPacket packet: NSData, sequenceNumber: UInt16, error: NSError) {
    }
    
    public func simplePing(pinger: SimplePing, didReceivePingResponsePacket packet: NSData, sequenceNumber: UInt16) {
        receiveDate = NSDate()
        if let sendDate  =  sendDate {
            let rtt = receiveDate?.timeIntervalSinceDate(sendDate)
            let avgmSec = rtt! * 1000
            let formatStr = String(format: "%.f", avgmSec)
            pingLabel.text = "\(formatStr) ms"
            pingLabel.textColor = "B2B2B2".color
        }
    }
    
    public func simplePing(pinger: SimplePing, didReceiveUnexpectedPacket packet: NSData) {
    }
    
}
