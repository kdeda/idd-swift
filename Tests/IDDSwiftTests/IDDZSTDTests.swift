//
//  IDDSwiftTests.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/9/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import XCTest
import Log4swift
import IDDSwift

@MainActor
final class IDDZSTDTests: XCTestCase {
    override func setUp() {
        super.setUp()

        Log4swift.configure(fileLogConfig: nil)
        // Self.logConfig = true
    }

    /**
     Runs some quick tests on ZSTD
     */
    func testZSTDCompress() async {
#if os(iOS)
#else
        let iddSwiftRootURL = URL.init(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        guard let enumerator = FileManager.default.enumerator(
            at: iddSwiftRootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        else { return }

        let swiftFiles = enumerator.compactMap { element -> URL? in
            guard let url = element as? URL,
                  url.pathExtension == "swift"
            else { return .none }
            return url
        }

        let clearChunks = (0 ..< 20).map { _ in swiftFiles.randomData(count: 10 * 1024 * 1024) }
        let byteCount = clearChunks.reduce(into: 0, { $0 += $1.count })

        let startDate1 = Date()
        let compressedChunks = clearChunks.map(\.zlibCompressed)
        let compressedByteCount = compressedChunks.reduce(into: 0, { $0 += $1.count })
        Log4swift[Self.self].dash("   compressed: '\(byteCount.decimalFormatted) bytes' to: '\(compressedByteCount.decimalFormatted) bytes' elapsedTime: '\(startDate1.elapsedTime)'")
        Log4swift[Self.self].info("   compressed: '\(byteCount.decimalFormatted) bytes' to: '\(compressedByteCount.decimalFormatted) bytes' elapsedTime: '\(startDate1.elapsedTime)'")

        let startDate2 = Date()
        let unCompressedChunks = compressedChunks.map(\.zlibUncompressed)
        let unCompressedByteCount = unCompressedChunks.reduce(into: 0, { $0 += $1.count })
        Log4swift[Self.self].info("un compressed: '\(compressedByteCount.decimalFormatted) bytes' to: '\(unCompressedByteCount.decimalFormatted) bytes' elapsedTime: '\(startDate2.elapsedTime)'")
        Log4swift[Self.self].dash("un compressed: '\(compressedByteCount.decimalFormatted) bytes' to: '\(unCompressedByteCount.decimalFormatted) bytes' elapsedTime: '\(startDate2.elapsedTime)'")

        XCTAssertEqual(unCompressedByteCount, byteCount)
        let matchingCount = clearChunks.enumerated().reduce(into: 0) { partialResult, nextItem in
            let uncompressed = unCompressedChunks[nextItem.offset]
            partialResult += (nextItem.element == uncompressed) ? 1 : 0
        }

        XCTAssertEqual(matchingCount, clearChunks.count)
#endif
    }
}

extension Array where Element == URL {
    /// create a chunk of data up to count
    ///
    fileprivate func noise_(count: Int) -> Data {
        var rng = SystemRandomNumberGenerator()
        var data = Data(count: count)
        data.withUnsafeMutableBytes { raw in
            let words = raw.bindMemory(to: UInt64.self)
            for i in words.indices { words[i] = rng.next() }
            for i in (words.count * 8)..<count {
                raw[i] = UInt8.random(in: .min ... .max, using: &rng)
            }
        }
        return data
    }

    fileprivate func randomData(count: Int) -> Data {
        let chunk: Data = {
            self.enumerated().reduce(into: Data(), { partialResult, nextItem in
                let data = Data.init(withURL: nextItem.element)
                partialResult.append(data)
            })
        }()

        var rv = chunk
        while rv.count < count {
            // noise
            rv.append(noise_(count: 1024))
            rv.append(chunk)
        }
        return rv
    }
}
