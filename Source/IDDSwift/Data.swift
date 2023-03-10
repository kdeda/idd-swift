//
//  Data.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import Crypto

public extension Data {
    init(withURL url: URL) {
        do {
            try self.init(contentsOf: url)
        } catch {
            self.init()
            Log4swift[Self.self].error("error: '\(error.localizedDescription)' We will return empty data.")
        }
    }
    
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
            else { return }
        append(data)
    }
    
    /**
     returns a unique fingerprint
     ie: 2E79D73C-EAB5-44E0-9DEC-75602872402E
     */
    var md5: String {
        let digest = Insecure.MD5.hash(data: self)
        var tokens = digest.map { String(format: "%02hhx", $0) }

        if tokens.count == 16 {
            tokens.insert("-", at: 4)
            tokens.insert("-", at: 7)
            tokens.insert("-", at: 10)
            tokens.insert("-", at: 13)

            if let uuid = UUID(uuidString: tokens.joined(separator: "").uppercased()) {
                return uuid.uuidString
            }
        }
        return tokens.joined(separator: "").uppercased()
    }
}
