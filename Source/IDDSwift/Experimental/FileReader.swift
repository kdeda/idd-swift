//
//  FileReader.swift
//  idd-swift
//
//  Created by Klajd Deda on 12/31/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if !os(macOS)
#else

import Foundation

/**
 Original code from https://infinum.com/blog/swift-non-copyable-types/
 */
final class FileReader {
    let maxLength = 100000
    let fileHandle: FileHandle
    let file: UnsafeMutablePointer<FILE>
    let fileName: String
    let fileSize: Int64
    var rowCount: Int

    init(fileURL: URL) throws {
        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        // Convert file descriptor to FILE*
        guard let file = fdopen(fileHandle.fileDescriptor, "r")
        else {
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(errno),
                userInfo: nil
            )
        }

        self.file = file
        self.fileName = fileURL.lastPathComponent
        self.fileSize = fileURL.logicalSize
        self.rowCount = 0
    }

    deinit {
        let success = fclose(file) == 0
        assert(success)
    }

    private func readLine(_ buffer: consuming FileChunk) throws -> FileChunk? {
        if fgets(buffer._buffer, Int32(maxLength), file) == nil {
            if feof(file) != 0 {
                return nil
            } else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            }
        }

        // Log4swift[Self.self].info("read: '\(currentChunk.asString)'")
        return buffer
    }

    func findLongestNonCopyable() throws -> String? {
        var longest: FileChunk? = nil
        var buffer: FileChunk = FileChunk(maxCount: maxLength)
        var longestCount: Int = 0

        rowCount = 0
        while let line: FileChunk = try readLine(buffer) {
            rowCount += 1
            if rowCount % 500_000 == 0 {
                let left = (try? fileHandle.offset()) ?? 0
                Log4swift[Self.self].info("[\(fileName)] parsed: '\(rowCount.decimalFormatted) lines' consumed: '\(left.decimalFormatted)' remaining: '\(fileSize.decimalFormatted) bytes'")
            }

            let count = line.bytes.count
            if count > longestCount {
                buffer = FileChunk(maxCount: maxLength)
                longest = consume line
                longestCount = count
            } else {
                buffer = consume line
            }
        }

        return longest?.asString
    }
}

#endif
