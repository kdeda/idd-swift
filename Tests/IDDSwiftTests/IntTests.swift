//
//  IntTests.swift
//  idd-swift
//
//  Created by Klajd Deda on 11/24/25.
//

import XCTest
import Log4swift
import IDDSwift
import CustomDump

@MainActor
final class IntTests: XCTestCase {
    override func setUp() {
        super.setUp()

        Log4swift.configure(fileLogConfig: nil)
    }

    func validate(_ expected: Int, _ string: String, radix: Radix) {
        // Log4swift[Self.self].info("string: '\(string)'")

        let data = string.data(using: .utf8) ?? Data()
        let bytes = [UInt8](data)
        let fastValue = Int64(bytes, radix: radix) ?? 0

        //  if expected != fastValue {
        //      Log4swift[Self.self].info("string: '\(string)' failed")
        //  }
        XCTAssert(expected == fastValue, "parsing: '\(string)' failed, expected: '\(expected)' parsed: '\(fastValue)'")
    }


    func testIntFromBytes() async {
        // known numbers
        validate(123, "000123", radix: .base10)
        validate(123, "00007b", radix: .base16)

        (0 ... 100).forEach { _ in
            // random numbers
            let randomValue = Int.random(in: ( 100 ... 100_000))
            let base16_string = String(randomValue, radix: 16)
            let referenceValue = Int(base16_string, radix: 16) ?? 0
            let base10_string = String(format: "%010d", referenceValue)

            validate(referenceValue, base10_string,                                   radix: .base10)
            validate(referenceValue, base16_string.leftPadding(to: 10, withPad: "0"), radix: .base16)
        }
    }
}
