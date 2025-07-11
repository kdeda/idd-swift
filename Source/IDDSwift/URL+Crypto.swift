//
//  URL+Crypto.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/3/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
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
        var tokens = digest.map { String(format: "%02hx", $0) }

        if tokens.count == 16 {
            tokens.insert("-", at: 4)
            tokens.insert("-", at: 7)
            tokens.insert("-", at: 10)
            tokens.insert("-", at: 13)

            //  // not sure we need this ...
            //  if let uuid = UUID(uuidString: tokens.joined(separator: "").uppercased()) {
            //      return uuid.uuidString
            //  }
        }
        return tokens.joined(separator: "").uppercased()
    }
}

fileprivate extension FileHandle {
    static let bufferLength = 256 * 1024

    func moreData(_ wasCancelled: inout Bool) -> Data? {
        guard !Task.isCancelled // preemptive cancellation
        else {
            wasCancelled = true
            // Log4swift[Self.self].info("url: '\(self.path)' was cancelled elapsedTime: '\(startDate.elapsedTime)'")
            return .none
        }

        let nextChunk = self.readData(ofLength: Self.bufferLength)
        guard !nextChunk.isEmpty
        else { return .none }

        return nextChunk
    }
}

public extension URL {
    var md5: String {
        guard let handle = try? FileHandle(forReadingFrom: self)
        else { return "" }
        defer {
            handle.closeFile()
        }
        let logicalSize = self.logicalSize
        guard logicalSize > 0
        else { return "" }

        let startDate = Date()
        var hasher = Insecure.MD5()
        var wasCancelled = false

        while let nextChunk = handle.moreData(&wasCancelled) {
            hasher.update(data: nextChunk)
        }

        guard !wasCancelled
        else { return "" }
        let data = Data(hasher.finalize())
        let rv = data.md5

        if startDate.elapsedTimeInMilliseconds > 10 {
            Log4swift[Self.self].info("url: '\(self.path)' md5: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }

    /**
     A lot faster than the md5, like 4x on m2 ultra
     */
    var sha256: String {
        guard let handle = try? FileHandle(forReadingFrom: self)
        else { return "" }
        defer {
            handle.closeFile()
        }
        let logicalSize = self.logicalSize
        guard logicalSize > 0
        else { return "" }

        let startDate = Date()
        var hasher = SHA256()
        var wasCancelled = false

        while let nextChunk = handle.moreData(&wasCancelled) {
            hasher.update(data: nextChunk)
        }

        guard !wasCancelled
        else { return "" }
        let data = Data(hasher.finalize())
        let rv = data.md5

        if startDate.elapsedTimeInMilliseconds > 125 {
            Log4swift[Self.self].info("url: '\(self.path)' sha256: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }
}
