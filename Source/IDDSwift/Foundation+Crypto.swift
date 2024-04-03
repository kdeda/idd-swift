//
//  Foundation+Crypto.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/3/24.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import Crypto

public extension Data {
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

public extension URL {
     var sha256: String {
        guard let handle = try? FileHandle(forReadingFrom: self)
        else { return "" }
        var hasher = SHA256()

        while autoreleasepool(invoking: {
            let nextChunk = handle.readData(ofLength: SHA256.blockByteCount)
            guard !nextChunk.isEmpty 
            else { return false }
            
            hasher.update(data: nextChunk)
            return true
        }) { }
        let digest = hasher.finalize()

        var tokens = digest.map { String(format: "%02x", $0) }

        if tokens.count == 32 {
            tokens.insert("-", at: 8)
            tokens.insert("-", at: 14)
            tokens.insert("-", at: 21)
            tokens.insert("-", at: 28)
        }

        return tokens.joined(separator: "").uppercased()
    }
}
