//
//  Config.swift
//  Potatso
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import RealmSwift
import PotatsoModel
import YAML

public enum ConfigError: ErrorType {
    case DownloadFail
    case SyntaxError
}

extension ConfigError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .DownloadFail:
            return "Download fail"
        case .SyntaxError:
            return "Syntax error"
        }
    }
    
}

public class Config {
    
    public var groups: [ConfigurationGroup] = []
    public var proxies: [Proxy] = []
    public var ruleSets: [RuleSet] = []
    
    let realm: Realm
    var configDict: [String: AnyObject] = [:]
    
    public init() {
        realm = try! Realm()
    }
    
    public func setup(string configString: String) throws {
        guard let object = try? YAMLSerialization.objectWithYAMLString(configString, options: kYAMLReadOptionStringScalars), yaml = object as? [String: AnyObject] else {
            throw ConfigError.SyntaxError
        }
        self.configDict = yaml
        try setupModels()
    }
    
    
    public func setup(url url: NSURL) throws {
        guard let string = try? String(contentsOfURL: url) else {
            throw ConfigError.DownloadFail
        }
        
        var proxies = ""
        
        let proxyStringFind = "[Proxy]";
        
        let proxyStringRange = string.rangeOfString(proxyStringFind, options: NSStringCompareOptions())
        
        if proxyStringRange != nil {
            
            let proxyString = string.substringFromIndex((proxyStringRange?.startIndex.advancedBy(7))!);
            
            let noteStringFind = "[";
            
            let noteStringRange = proxyString.rangeOfString(noteStringFind, options: NSStringCompareOptions())
            
            if  noteStringRange != nil {
                let range = Range(start: proxyString.startIndex.advancedBy(0), end: (noteStringRange?.startIndex.advancedBy(-1))!)
                
                let proxyStringResult = proxyString.substringWithRange(range)
                
                proxies +=  self.turnProxy(proxyStringResult)
                
            }
        }
        
        var  rules = ""
        
        let stringFind = "[Rule]";
        
        let range = string.rangeOfString(stringFind, options: NSStringCompareOptions()) //Swift 2.0
        
        guard (range?.startIndex) != nil else {
            
            try setup(string: string)
            
            return
        }
        
        if let startIndex = range?.startIndex {
            
            let ruleString = string.substringFromIndex(startIndex);
            
            let rulesStringReplace = "# " + ruleString
            
            rules =  self.addYamlRule(rulesStringReplace)
        }
        
        let reusltString = proxies + rules
        
        if reusltString.characters.count > 0 {
            try setup(string: reusltString)
        }else{
            try setup(string: string)
        }
        
    }
    
    public func turnProxy(string:String) -> String {
        
        let myStrings = string.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        var result: String = ""
        
        result  +=  "proxies:\r"
        
        for index in 0..<myStrings.count {
            
            let subString =  myStrings[index]
            
            if (subString.characters.count<=0) {
                continue;
            }
            
            let pattern = "#";
            let regular = try! NSRegularExpression(pattern: pattern, options:.CaseInsensitive)
            let results = regular.matchesInString(subString, options: .ReportProgress , range: NSMakeRange(0, subString.characters.count))
            
            if results.count > 0 {
                continue;
            }
            
            let subArray  = subString.componentsSeparatedByString(",")
            
            let name:String = subArray[0].substringToIndex((subArray[0].rangeOfString("=")?.startIndex.advancedBy(0))!);
            
            result  +=  "- name: " + name + "\r"
            result  +=  "  host: " + subArray[1] + "\r"
            result  +=  "  port: " + subArray[2] + "\r"
            result  +=  "  type: " + "SHADOWSOCKS" + "\r"
            result  +=  "  password: " + subArray[4] + "\r"
            result  +=  "  encryption: " + subArray[3] + "\r"
        }
        
        return result
        
    }
    
    public func addYamlRule(string:String) ->String {
        
        let myStrings = string.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        var result: String = "ruleSets:\r- name: Default\r  rules: \r"
        for index in 0..<myStrings.count {
            
            let subString =  myStrings[index]
            
            if (subString.characters.count<=0) {
                result  +=  "\r"
                continue;
            }
            let patternNote = "//";
            let regularNote = try! NSRegularExpression(pattern: patternNote, options:.CaseInsensitive)
            let resultsNote = regularNote.matchesInString(subString, options: .ReportProgress , range: NSMakeRange(0, subString.characters.count))
            
            if resultsNote.count > 0 {
                continue;
            }
            let pattern = "#";
            let regular = try! NSRegularExpression(pattern: pattern, options:.CaseInsensitive)
            let results = regular.matchesInString(subString, options: .ReportProgress , range: NSMakeRange(0, subString.characters.count))
            
            if results.count > 0 {
                result  += subString + "\r"
                continue;
            }
            let resolveString = "no-resolve";
            let resolveRegular = try! NSRegularExpression(pattern: resolveString, options:.CaseInsensitive)
            let resolveResults = resolveRegular.matchesInString(subString, options: .ReportProgress , range: NSMakeRange(0, subString.characters.count))
            if resolveResults.count > 0 {
                let filtered = subString.stringByReplacingOccurrencesOfString(",no-resolve", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                result  += "  - " + filtered + "\r"
                continue;
            }
            let remote_dnsString = "force-remote-dns";
            let remote_dnsRegular = try! NSRegularExpression(pattern: remote_dnsString, options:.CaseInsensitive)
            let remote_dnsResults = remote_dnsRegular.matchesInString(subString, options: .ReportProgress , range: NSMakeRange(0, subString.characters.count))
            if remote_dnsResults.count > 0 {
                let filtered = subString.stringByReplacingOccurrencesOfString(",force-remote-dns", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                result  += "  - " + filtered + "\r"
                continue;
            }
            if (subString.hasSuffix("FINAL,DIRECT")) {
                result  += "  - FINAL,,DIRECT" + "\r"
                continue;
            }
            result  += "  - " + subString + "\r"
        }
        
        return result
    }
    
    
    public func save() throws {
        do {
            try realm.commitWrite()
        }catch {
            throw error
        }
    }
    
    func setupModels() throws {
        realm.beginWrite()
        do {
            try setupProxies()
            try setupRuleSets()
            try setupConfigGroups()
        }catch {
            realm.cancelWrite()
            throw error
        }
    }
    
    func setupProxies() throws {
        
        if let proxiesConfig = configDict["proxies"] as? [[String: AnyObject]] {
            proxies = try proxiesConfig.map({ (config) -> Proxy? in
                return try Proxy(dictionary: config, inRealm: realm)
            }).filter { $0 != nil }.map { $0! }
            try proxies.forEach {
                try $0.validate(inRealm: realm)
                realm.add($0)
            }
        }
    }
    
    func setupRuleSets() throws{
        if let proxiesConfig = configDict["ruleSets"] as? [[String: AnyObject]] {
            ruleSets = try proxiesConfig.map({ (config) -> RuleSet? in
                return try RuleSet(dictionary: config, inRealm: realm)
            }).filter { $0 != nil }.map { $0! }
            try ruleSets.forEach {
                try $0.validate(inRealm: realm)
                realm.add($0)
            }
        }
    }
    
    func setupConfigGroups() throws{
        if let proxiesConfig = configDict["configGroups"] as? [[String: AnyObject]] {
            groups = try proxiesConfig.map({ (config) -> ConfigurationGroup? in
                return try ConfigurationGroup(dictionary: config, inRealm: realm)
            }).filter { $0 != nil }.map { $0! }
            try groups.forEach {
                try $0.validate(inRealm: realm)
                realm.add($0)
            }
        }
    }
    
}