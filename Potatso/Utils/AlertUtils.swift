//
//  AlertUtils.swift
//  Potatso
//
//  Created by LEI on 4/10/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation

struct Alert {
    
    static func show(vc: UIViewController, title: String? = nil, message: String? = nil, confirmCallback: (() -> Void)?, cancelCallback: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .Default, handler: { (action) in
            confirmCallback?()
        }))
        alert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .Cancel, handler: { (action) in
            cancelCallback?()
        }))
        vc.presentViewController(alert, animated: true, completion: nil)
    }
    
    static func show(vc: UIViewController, title: String? = nil, message: String? = nil, confirmCallback: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .Default, handler: { (action) in
            confirmCallback?()
        }))
        vc.presentViewController(alert, animated: true, completion: nil)
    }
    
}