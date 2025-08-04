//
//  URLCryptoTests.swift
//  idd-swift
//
//  Created by Klajd Deda on 8/4/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import XCTest
import Log4swift
import IDDSwift

@MainActor
final class URLCryptoTests: XCTestCase {
    override func setUp() {
        super.setUp()

        Log4swift.configure(fileLogConfig: nil)
    }

    /**
     Create a file, calculate md5 old fashion and new fashion and assert.
     */
    func testMD5() async {
#if os(iOS)
#else
        let logFile = URL(fileURLWithPath: "/tmp/testMD5.log")
        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")

//        try? FileManager.default.removeItem(at: logFile)
//        try? "".write(to: logFile, atomically: true, encoding: .utf8)
//        logFile.appendUUIDs(1_000_000)

        let md5_1 = logFile.md5_deprecated
        let md5_2 = logFile.calculateHash(Insecure.MD5()).md5
        XCTAssert(md5_1 == md5_2)
        Log4swift[Self.self].info(" Insecure.MD5: '\(md5_2)'")

        let sha1_2 = logFile.calculateHash(Insecure.SHA1()).md5
        Log4swift[Self.self].info("Insecure.SHA1: '\(sha1_2)'")

        let sha256_1 = logFile.sha256_deprecated
        let sha256_2 = logFile.calculateHash(SHA256()).md5
        Log4swift[Self.self].info("       SHA256: '\(sha256_2)'")

        XCTAssert(sha256_1 == sha256_2)

        // let logFile2 = URL(fileURLWithPath: "/Applications/Firefox.app/Contents/MacOS/XUL")
        await logFile.benchMark(prefix: " Insecure.MD5", count: 100, { _ = logFile.calculateHash(Insecure.MD5()).md5 })
        await logFile.benchMark(prefix: "Insecure.SHA1", count: 100, { _ = logFile.calculateHash(Insecure.SHA1()).md5 })
        await logFile.benchMark(prefix: "       SHA256", count: 100, { _ = logFile.calculateHash(SHA256()).md5 })

        Log4swift[Self.self].dash("benchMark")

#endif
    }
}

fileprivate extension URL {
    func appendUUIDs(_ uuidCount: Int) {
        var buffer = Data()

        (0 ..< uuidCount).forEach { _ in
            buffer.append(UUID().uuidString.data(using: .ascii) ?? Data())
            if buffer.count > 10_000_000 {
                append(data: buffer)
                buffer.removeAll()
            }
        }
        if buffer.count > 0 {
            append(data: buffer)
            buffer.removeAll()
        }
    }

    func benchMark(prefix: String, count: Int, _ calculateHash: @escaping @Sendable () -> Void) async {
        let startDate = Date()

        await withTaskGroup(of: Void.self) { group  in
            (0 ..< count).forEach { _ in
                group.addTask {
                    calculateHash()
                }
            }
        }

        let bytes = self.logicalSize * Int64(count)
        let speed = 1000 * (bytes / Int64(startDate.elapsedTimeInMilliseconds))
        Log4swift[Self.self].info("\(prefix): '\(bytes.decimalFormatted) bytes' in: '\(startDate.elapsedTime)' or: '\(speed.compactFormatted) / second'")
    }
}
