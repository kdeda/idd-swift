//
//  UserDefaultsValue.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/25/20.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

/**
 Convenience type to implement a PropertyWrapper
 I will note that even this code is simple it has been really hard to use it clear it from buggs.
 It promotes a strange situation.
 
 defaults read ~/Library/Preferences/com.id-design.v8.whatsize.plist

 It seems that @propertyWrapper do break TCA, March 2023
 */
@propertyWrapper
public struct UserDefaultsValue<Value>: Equatable, Sendable where Value: Equatable, Value: Codable, Value: Sendable {
    let key: String
    let defaultValue: Value
    /// this maps to Bundle.main.bundleIdentifier, ie: 'com.id-design.v8.WhatSize'
    /// defaults read ~/Library/Preferences/com.id-design.v8.whatsize.plist
    /// 
    @available(macOS, deprecated: 1.3.7, message: "Use 'init(_ defaultValue: Value, forKey: String)', instead.")
    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public init(_ defaultValue: Value, forKey: String) {
        self.key = forKey
        self.defaultValue = defaultValue
    }

    /**
     if the value is nil return defaultValue
     if the value is an empty string return defaultValue
     otherwise return the value
     
     to avoid collisions with the old user default code we will attempt to read from the "$key.json"
     and write to "$key.json"
     as we write to "$key.json" we will also remove the old default at "$key"
     */
    public var wrappedValue: Value {
        get {
            // Log4swift[Self.self].info("loading: '\(self.key)'")
            let value: Value? = {
                guard let storedValue = UserDefaults.standard.object(forKey: key.jsonKey) as? String
                else { return UserDefaults.standard.object(forKey: key) as? Value }
                let encoder = JSONDecoder()
                
                encoder.dateDecodingStrategy = .iso8601
                // Log4swift[Self.self].info("loaded raw value \(self.key): '\(storedValue ?? "unknown ...")'")
                let data = storedValue.data(using: .utf8) ?? Data()
                return try? encoder.decode(Value.self, from: data)
            }()
                
            if let stringValue = value as? String,
               stringValue.isEmpty {
                // for string values we want to equate nil with empty string as well
                return defaultValue
            }
            // Log4swift[Self.self].info("loaded: '\(self.key)'")
            // Log4swift[Self.self].info("loaded \(self.key): '\(value ?? defaultValue)'")
            return value ?? defaultValue
        }
        set {
            do {
                let encoder = JSONEncoder()
                
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(newValue)
                let storedValue = String(data: data, encoding: .utf8) ?? ""
                
                UserDefaults.standard.set(storedValue, forKey: key.jsonKey)
                UserDefaults.standard.removeObject(forKey: key)
                // Log4swift[Self.self].info("stored \(self.key): '\(storedValue)'")
            } catch {
                Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
            }
        }
    }
}

fileprivate extension String {
    var jsonKey: String {
        self + ".json"
    }
}
