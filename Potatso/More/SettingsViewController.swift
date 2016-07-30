//
//  MoreViewController.swift
//  Potatso
//
//  Created by LEI on 1/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import Eureka
import Appirater
import ICSMainFramework
import MessageUI
import SafariServices
import PotatsoLibrary

enum FeedBackType: String, CustomStringConvertible {
    case Email = "Email"
    case Forum = "Forum"
    case None = ""
    
    var description: String {
        return rawValue.localized()
    }
}



class SettingsViewController: FormViewController, MFMailComposeViewControllerDelegate, SFSafariViewControllerDelegate {
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "More".localized()
        generateForm()
    }
    
    func generateForm() {
        form
            +++ Section()
            <<< ButtonRow() {
                $0.title = "User Manual".localized()
                $0.presentationMode = PresentationMode.PresentModally(controllerProvider: ControllerProvider.Callback(builder: { [unowned self]() -> BaseSafariViewController in
                    let url = "http://freedoms.land/help.html"
                    let vc = BaseSafariViewController(URL: NSURL(string: url)!, entersReaderIfAvailable: false)
                    vc.delegate = self
                    return vc
                    }), completionCallback: { (vc) -> () in
                        
                })
        }
        let feedbackSection = Section()
        feedbackSection
            <<< LabelRow() {
                $0.title = "Share with friends".localized()
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .Default
                    cell.accessoryType = .DisclosureIndicator
                }).onCellSelection({ [unowned self] (cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    var shareItems: [AnyObject] = []
                    shareItems.append("Freedoms,A Powerful Network Tool! [http://freedoms.land/]")
                    shareItems.append(UIImage(named: "AppIcon60x60")!)
                    let shareVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                    self.presentViewController(shareVC, animated: true, completion: nil)
                    })
        form +++ feedbackSection
        
        form +++ Section()
            <<< LabelRow() {
                $0.title = "Website".localized()
                $0.value = "http://freedoms.land"
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .Default
                    cell.accessoryType = .DisclosureIndicator
                }).onCellSelection({ (cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    UIApplication.sharedApplication().openURL(NSURL(string: "http://freedoms.land")!)
                })
            <<< LabelRow() {
                $0.title = "Version".localized()
                $0.value = AppEnv.fullVersion
        }
        
    }
    
    @objc func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
}