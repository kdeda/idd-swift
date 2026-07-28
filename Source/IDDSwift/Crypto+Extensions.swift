//
//  Crypto+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/3/24.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import Crypto

public extension Data {
    func digestWithHasher<Hasher: HashFunction>(_ hasher: Hasher) -> Data {
        var hasher_ = hasher
        
        hasher_.update(data: self)
        return Data(hasher_.finalize())
    }

    /// Assumes self is a result of digestWithHasher
    var digestString: String {
        let tokens = self.map { String(format: "%02hhx", $0) }
        return tokens.joined(separator: "")
    }

    var md5Digest: Data {
        digestWithHasher(Insecure.MD5())
    }

    /**
     returns a unique fingerprint
     ie: 2E79D73C-EAB5-44E0-9DEC-75602872402E
     */
    var md5: String {
        var tokens = md5Digest.map { String(format: "%02hhx", $0) }

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

    var sha1Digest: Data {
        digestWithHasher(Insecure.SHA1())
    }
    
    var sha1: String {
        sha1Digest.digestString
    }

    var sha256Digest: Data {
        digestWithHasher(SHA256())
    }

    var sha256: String {
        sha256Digest.digestString
    }
}

fileprivate extension FileHandle {
    static let bufferLength = 512 * 1024 // 500kb at once

    func readData(_ bufferLength: Int) -> Data? {
        guard !Task.isCancelled // preemptive cancellation
        else { return .none }

        guard let nextChunk = try? self.read(upToCount: bufferLength)
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
                var endOfFile = false

                while !Task.isCancelled || !endOfFile {
                    autoreleasepool {
                        // release any temporary as soon as possible
                        if let nextChunk = try? self.read(upToCount: Self.bufferLength),
                           !nextChunk.isEmpty
                        {
                            bytesRead += nextChunk.count
                            continuation.yield(nextChunk)
                        }
                        else {
                            endOfFile = true
                        }
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
    enum CalculateHashError: Error {
        case emptyFile
        case canceled
    }

    /**
     Will read the bytes from the file represented by self using chunks of
     FileHandle.bufferLength at a time and hash it according to hasher.
     Will throw if you are trying to work on a file not in your user space.
     Will throw if Task was canceled or file is empty.

     Use it as such
     ```
     let url = URL() // assume this is readable
     let digest = try url.digestFromHasher(SHA256())
     let sha256 = digest.compactMap { String(format: "%02x", $0) }.joined()
     ```
     Co-operates in the Task cancelation, so it can early exit on large files.
     */
    func digestWithHasher<Hasher: HashFunction>(_ hasher: Hasher) throws -> Data {
        let handle = try FileHandle(forReadingFrom: self)
        defer {
            handle.closeFile()
        }
        
        let logicalSize = self.logicalSize
        guard logicalSize > 0
        else {
            throw CalculateHashError.emptyFile
        }

        var hasher_ = hasher
        var endOfFile = false
        while !endOfFile {
            autoreleasepool {
                // release any temporary as soon as possible
                if let nextChunk = handle.readData(FileHandle.bufferLength),
                   !nextChunk.isEmpty
                {
                    hasher_.update(data: nextChunk)
                }
                else {
                    endOfFile = true
                }
            }
        }

        guard !Task.isCancelled // preemptive cancellation
        else {
            throw CalculateHashError.canceled
        }

        return Data(hasher_.finalize())
    }

    /**
     Slow on apple silicon as of Xcode26
     */
    var md5Digest: Data? {
        let startDate = Date()
        let rv: Data? = {
            do {
                return try digestWithHasher(Insecure.MD5())
            } catch {
                Log4swift[Self.self].error("error: '\(error)'")
                return .none
            }
        }()

        if let rv, startDate.elapsedTimeInMilliseconds > 100 {
            Log4swift[Self.self].info("url: '\(self.path)' with: '\(logicalSize.decimalFormatted) bytes' completed in: '\(startDate.elapsedTime)'")
        }
        return rv
    }
    
    var md5: String? {
        md5Digest?.md5
    }

    /**
     A lot faster than the md5, like 3x on apple silicon
     */
    var sha1Digest: Data? {
        let startDate = Date()
        let rv: Data? = {
            do {
                return try digestWithHasher(Insecure.SHA1())
            } catch {
                Log4swift[Self.self].error("error: '\(error)'")
                return .none
            }
        }()

        if startDate.elapsedTimeInMilliseconds > 100 {
            Log4swift[Self.self].info("url: '\(self.path)' with: '\(logicalSize.decimalFormatted) bytes' completed in: '\(startDate.elapsedTime)'")
        }
        return rv
    }
    
    var sha1: String? {
        sha1Digest?.digestString
    }

    /**
     A lot faster than the md5, like 3x on m2 ultra
     */
    var sha256Digest: Data? {
        let startDate = Date()
        let rv: Data? = {
            do {
                return try digestWithHasher(SHA256())
            } catch {
                Log4swift[Self.self].error("error: '\(error)'")
                return .none
            }
        }()

        if let rv, startDate.elapsedTimeInMilliseconds > 1_000 {
            Log4swift[Self.self].info("url: '\(self.path)' with: '\(logicalSize.decimalFormatted) bytes' completed in: '\(startDate.elapsedTime)'")
        }
        return rv
    }
    
    var sha256: String? {
        sha256Digest?.digestString
    }
}
