//
//  UIManager.swift
//  Potatso
//
//  Created by LEI on 12/27/15.
//  Copyright © 2015 TouchingApp. All rights reserved.
//

import Foundation
import ICSMainFramework
import PotatsoLibrary
import Aspects

class UIManager: NSObject, AppLifeCycleProtocol {
    
    var keyWindow: UIWindow? {
        return UIApplication.sharedApplication().keyWindow
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        UIView.appearance().tintColor = Color.Brand
        
        UITableView.appearance().backgroundColor = Color.Background
        UITableView.appearance().separatorColor = Color.Separator
        
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().barTintColor = Color.NavigationBackground
        
        UITabBar.appearance().translucent = false
        UITabBar.appearance().backgroundColor = Color.TabBackground
        UITabBar.appearance().tintColor = Color.TabItemSelected

        UINavigationBar.appearance().barTintColor = UIColor(red:0.23, green:0.65, blue:0.34, alpha:1.00)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        UINavigationBar.appearance().barStyle = UIBarStyle.Black
        keyWindow?.rootViewController = makeRootViewController()
        return true
    }
    
    func makeRootViewController() -> UITabBarController {
        let tabBarVC = UITabBarController()
        tabBarVC.viewControllers = makeChildViewControllers()
        tabBarVC.selectedIndex = 0
        return tabBarVC
    }
    
    func makeChildViewControllers() -> [UIViewController] {
        CurrentGroupManager.shared.group = Manager.sharedManager.defaultConfigGroup
        let inset = UIEdgeInsetsMake(6, 0, -6, 0)
        let cons: [(UIViewController.Type, String)] = [(HomeVC.self, "Home"),(SettingsViewController.self, "More")]
        return cons.map {
            let vc = UINavigationController(rootViewController: $0.init())
            vc.tabBarItem = UITabBarItem(title: "", image: $1.originalImage, selectedImage: $1.templateImage)
            vc.tabBarItem.imageInsets = inset
            return vc
        }
    }
    
}

extension UITabBar {
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
        super.sizeThatFits(size)
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 44
        return sizeThatFits
    }
}