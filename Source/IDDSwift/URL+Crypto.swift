//
//  URL+Crypto.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/3/24.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
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

    func readData() -> Data? {
        guard !Task.isCancelled // preemptive cancellation
        else { return .none }

        guard let nextChunk = try? self.read(upToCount: Self.bufferLength)
        else { return .none }
        return nextChunk
    }

    /**
     Maximum chunk is FileHandle.bufferLength
     Not really used but could be a cute addition to the FileHandle
     */
    var readDataStream: AsyncStream<Data> {
        AsyncStream<Data> { continuation in
            let task = Task.detached {
                var bytesRead = 0

                while !Task.isCancelled {
                    if let nextChunk = try? self.read(upToCount: Self.bufferLength) {
                        bytesRead += nextChunk.count
                        continuation.yield(nextChunk)
                    } else {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

public extension URL {
    /**
     This func is async ready, it means that when you kill the task that this call was made form, this call will terminate asap
     Generic, able to use any algorithm that conforms to HashFunction
     upon failure or current task cancelation you will get an empty Data
     
     You can use it as such
     ```
     let url = URL() // assume this exists
     let rv = url.calculateHash(SHA256()).md5
     ```
     */
    func calculateHash<Hasher: HashFunction>(_ hasher: Hasher) -> Data {
        guard let handle = try? FileHandle(forReadingFrom: self)
        else { return Data() }
        defer {
            handle.closeFile()
        }
        let logicalSize = self.logicalSize
        guard logicalSize > 0
        else { return Data() }

        var hasher_ = hasher
        while let nextChunk = handle.readData() {
            hasher_.update(data: nextChunk)
        }

        guard !Task.isCancelled // preemptive cancellation
        else { return Data() }

        return Data(hasher_.finalize())
    }

    /**
     Slow on apple silicon as of Xcode26
     */
    var md5: String {
        let startDate = Date()
        let rv = calculateHash(Insecure.MD5()).md5

        if startDate.elapsedTimeInMilliseconds > 50 {
            Log4swift[Self.self].info("url: '\(self.path)' md5: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }

    /**
     A lot faster than the md5, like 3x on apple silicon
     */
    var sha1: String {
        let startDate = Date()
        let rv = calculateHash(Insecure.SHA1()).md5

        if startDate.elapsedTimeInMilliseconds > 50 {
            Log4swift[Self.self].info("url: '\(self.path)' sha1: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }

    /**
     A lot faster than the md5, like 3x on m2 ultra
     */
    var sha256: String {
        let startDate = Date()
        let rv = calculateHash(SHA256()).md5

        if startDate.elapsedTimeInMilliseconds > 20 {
            Log4swift[Self.self].info("url: '\(self.path)' sha256: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }
}

/**
Deprecated, not used
 */
public extension URL {
    var md5_deprecated: String {
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

        while let nextChunk = handle.readData() {
            hasher.update(data: nextChunk)
        }

        guard !Task.isCancelled // preemptive cancellation
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
    var sha256_deprecated: String {
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

        while let nextChunk = handle.readData() {
            hasher.update(data: nextChunk)
        }

        guard !Task.isCancelled // preemptive cancellation
        else { return "" }
        let data = Data(hasher.finalize())
        let rv = data.md5

        if startDate.elapsedTimeInMilliseconds > 125 {
            Log4swift[Self.self].info("url: '\(self.path)' sha256: '\(rv)' from: '\(logicalSize.decimalFormatted) bytes' elapsedTime: '\(startDate.elapsedTime)'")
        }
        return rv
    }
}
