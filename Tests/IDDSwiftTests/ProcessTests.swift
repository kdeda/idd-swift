//
//  ProcessTests.swift
//  IDDSwift
//
//  Created by Klajd Deda on 5/16/25.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import XCTest
import Log4swift
import IDDSwift

final class ProcessTests: XCTestCase {
    nonisolated(unsafe)
    static var logConfig = false

    override func setUp() {
        super.setUp()
        guard !Self.logConfig
        else { return }
        Self.logConfig = true
        Log4swift.configure(fileLogConfig: nil)
    }

    /**
     May 10, 2025
     Process.stdString had a nasty concurrency bug that happened once in a while
     This test allowed us to find it and plug it.

     Roight click and run the test mroe than 100 times to see it
     */
    func testHeavyProcessLoad() async throws {
#if os(macOS)
        func processRows() -> [String] {
            let string = Process.stdString(taskURL: URL(fileURLWithPath: "/bin/ps"), arguments: ["-ceo", "pid=,comm="])
            let rows = string.lowercased()
                .components(separatedBy: "\n")
                .filter({ !$0.isEmpty })
                .sorted(by: <)

            if rows.count < 785 {
                // boom
                Log4swift[Self.self].error("pidsByProcess: \n\t'\(string)'")
                Log4swift[Self.self].dash("pidsByProcess:")
            }
            return rows
        }

        func testPids() {
            let rows = processRows()
            XCTAssert(rows.count > 785)
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                testPids()
            }
            group.addTask {
                testPids()
            }
            group.addTask {
                testPids()
            }
            group.addTask {
                testPids()
            }
            group.addTask {
                testPids()
            }
        }
#endif
    }
}
