//
//  Bundle.swift
//  IDDSwift
//
//  Created by Klajd Deda on 7/26/18.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension Bundle {
    static func with(appName appName_dot_app: String) -> Bundle? {
        let urls = [
            URL.home.appendingPathComponent("Developer/build/Release/"),
            URL.home.appendingPathComponent("Developer/build/Debug/")
        ]
        
        let bundles = urls.compactMap { Bundle.init(url: $0.appendingPathComponent(appName_dot_app)) }
        return bundles.first(where: { $0.executableURL != nil })
    }
    
    /*
     * Wrapper for use in helper apps
     * To unpack use the counter part daemonVersion
     */
    var daemonVersion: String {
        let rv: String = {
            let json = [
                "CFBundleShortVersionString": Bundle.main[.info, "CFBundleShortVersionString", "1.0.1"],
                "CFBundleVersion": Bundle.main[.info, "CFBundleVersion", "1010"]
            ]
            
            do {
                let jsonBytes = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                
                return String(data: jsonBytes, encoding: .utf8)!
            } catch let error as NSError {
                Log4swift[Self.self].error("error: '\(error)'")
                Log4swift[Self.self].error("json: '\(json)'")
                return ""
            }
        }()
        
        Log4swift[Self.self].info("daemonVersion: '\(rv)'")
        return rv
    }
    
    func daemonVersion(fromJSON daemonVersionJSON: String) -> [String: String] {
        if let jsonBytes = daemonVersionJSON.data(using: .utf8) {

            do {
                if let daemonVersion = try JSONSerialization.jsonObject(with: jsonBytes, options: .allowFragments) as? [String : String] {
                    Log4swift[Self.self].info("result: '\(daemonVersion)'")
                    return daemonVersion
                }
            } catch let error as NSError {
                Log4swift[Self.self].error("error: '\(error)'")
                Log4swift[Self.self].error("daemonVersionJSON: '\(daemonVersionJSON)'")
            }
        }
        
        return ["CFBundleShortVersionString": "0.0.0", "CFBundleVersion": "0000"]
    }
    
    var isDevelopment: Bool {
        let build = URL.home.appendingPathComponent("Developer/build").path

        if let executableURL = self.executableURL {
            return executableURL.path.hasPrefix(build)
        }
        
        return false
    }
    
    enum SectionType {
        case info
        case localizedInfo
    }
    
    // convenience access
    subscript<T>(from: SectionType, key: String, defaultValue: T) -> T {
        let dictionary: [String: Any]? = {
            switch from {
            case .info: return infoDictionary
            case .localizedInfo: return localizedInfoDictionary
            }
        }()
        if let dictionary = dictionary {
            guard let rv = dictionary[key] as? T
            else { return defaultValue }
            return rv
        }
        return defaultValue
    }
    
    var appVersion: AppVersion {
        return AppVersion()
    }
}

public extension Bundle {
    struct AppVersion {
        public let id: String
        public let name: String
        public let shortVersion: String
        public let buildNumber: Int
        public let startDate: String
        public let creationDate: String
        public let creationDateLocalized: String

        public init() {
            id = Bundle.main.bundleIdentifier ?? "com.mycompany.myapp"
            /**
             grab the localized value if there is one, otherwise fallback to info
             the localized value can display something different than the value from the info plist
             say "My Cool App", vs "MyCoolApp"
             this allows us to display with spaces but have no spaces on file system
             */
            name = Bundle.main[.localizedInfo, "CFBundleName", Bundle.main[.info, "CFBundleName", "myapp"]]
            shortVersion = Bundle.main[.info, "CFBundleShortVersionString", "1.0.1"]
            buildNumber = Int(Bundle.main[.info, "CFBundleVersion", "1010"]) ?? 1010
            startDate = Date.init().stringWithDefaultFormat
            let creationDate_ = Bundle.main.executableURL?.creationDate ?? Date.distantPast
            creationDate = creationDate_.stringWithDefaultFormat
            creationDateLocalized = creationDate_.string(withFormat: "MMMM dd, yyyy")
        }
        
        public var shortDescription: String {
            let rv = [
                "\(name) \(shortVersion)",
                "build: \(buildNumber)",
                "on: \(creationDate)",
                "started: \(startDate)"
            ]
            return rv.joined(separator: ", ")
        }
    }
}
