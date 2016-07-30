//
//  DBInitializer.swift
//  Potatso
//
//  Created by LEI on 3/8/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import ICSMainFramework
import NetworkExtension

class DataInitializer: NSObject, AppLifeCycleProtocol {
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        do {
            try Manager.sharedManager.setup()
        }catch {
            error.log("Fail to setup manager")
        }
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        _ = try? Manager.sharedManager.regenerateConfigFiles()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        _ = try? Manager.sharedManager.regenerateConfigFiles()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        deleteOrphanRules()
    }

    func deleteOrphanRules() {
        let orphanRules = defaultRealm.objects(Rule).filter("rulesets.@count == 0")
        _ = try? defaultRealm.write({
            defaultRealm.delete(orphanRules)
        })
    }

}
