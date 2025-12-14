//
//  URLReadLinesTest.swift
//  idd-swift
//
//  Created by Klajd Deda on 11/15/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Testing
import Foundation
import Log4swift
import CustomDump
@testable import IDDSwift

/**
 Helper model data
 */
fileprivate struct RowItem: Equatable, Sendable {
    static let separator_: Character = "|"
    static let separator = separator_.asciiValue!

    let rowID: Int
    let rowAction: String
    let rowPathURL: URL
    
    static func generateRows(_ rowCount: Int) -> [RowItem] {
        let rv = (0 ... rowCount).reduce(into: [RowItem]()) { partialResult, nextItem in
            let rowPathURL: URL = {
                let rowFilePathCount = Int.random(in: 2 ..< 6)
                let rv = (1 ..< rowFilePathCount).reduce(into: URL.home.appendingPathComponent("Desktop")) { partialResult, nextItem in
                    let fileName = String(format: "%03d", Int.random(in: 1 ..< 30))
                    
                    partialResult = partialResult.appendingPathComponent(fileName)
                }
                return rv.appendingPathExtension("txt")
            }()
            
            partialResult.append(.init(
                rowID: nextItem,
                rowAction: "action_\(Int.random(in: 11 ..< 15))",
                rowPathURL: rowPathURL
            ))
        }
        
        return rv
    }
    
    var textRow: String {
        "\(rowID)\(Self.separator_)\(rowAction)\(Self.separator_)\(rowPathURL.path)"
    }
    
    init(rowID: Int, rowAction: String, rowPathURL: URL) {
        self.rowID = rowID
        self.rowAction = rowAction
        self.rowPathURL = rowPathURL
    }
    
    init?(bytes: ArraySlice<UInt8>) {
        let columns = bytes.components(separatedBy: Self.separator)
        guard columns.count == 3
        else {
            let rowString = String(decoding: bytes, as: UTF8.self)
            Log4swift[Self.self].error("could not parse: \(rowString)")
            return nil
        }
        
        let rowID_ = Int(columns[0])
        self.rowID = rowID_ ?? 0

        let rowAction_ = String(data: (Data(columns[1])), encoding: .utf8)
        self.rowAction = rowAction_ ?? ""
        
        let rowPath_ = String(data: (Data(columns[2])), encoding: .utf8)
        self.rowPathURL = URL.init(filePath: rowPath_ ?? "/tmp/unknown_idd_file.txt")
    }
}

struct URLReadLinesTest {
    /**
     ```
     find /Library/Backblaze.bzpkg/ -name "bz_done*0.dat" -exec cat {} \; >> /tmp/testBZDone.log
     find /Library/Backblaze.bzpkg/ -name "bz_done*0.dat" -exec cat {} \; >> /tmp/testBZDone.log
     ```
     */
    @Test func testBzDoneReadLines() async {
#if os(iOS)
#else
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/IDDSwift")
        Log4swift.configureCompactSettings()
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "IDDSwift", appSuffix: "", daysToKeep: 30))

        // find /Library/Backblaze.bzpkg/ -name "bz_done*0.dat" -exec cat {} \; >> /tmp/testBZDone.log
        let filePathURL = URL(fileURLWithPath: "/tmp/testBZDone.log")
        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")

        #expect(filePathURL.fileExist == true, "Please create the /tmp/testBZDone.log")

        await withTaskGroup(of: Void.self) { group  in
            /// run the process in a task, when it completes we will finish the continuation
            group.addTask {
                guard let stream = try? filePathURL.readLines()
                else { return }
                let startDate = Date()
                var chunkCounts = 0
                var totalBytes = 0

                for await rows in stream {
                    chunkCounts += rows.count
                    totalBytes += rows.reduce(into: 0, { partialResult, nextItem in
                        partialResult += nextItem.count
                    })
                }

                Log4swift[Self.self].info("read: '\(totalBytes.decimalFormatted) bytes' '\(chunkCounts.decimalFormatted) chunks', in :'\(startDate.elapsedTime)'")
                #expect(totalBytes == 4403010192)
            }
        }

        Log4swift[Self.self].dash("benchMark")
#endif
    }

    /**
     When an ArraySlice is sliced, the idexes remain the old ones
     This test asserts we do not barf/crash
     */
    @Test func testPartialSlices() async {
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/IDDSwift")
        Log4swift.configureCompactSettings()
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "IDDSwift", appSuffix: "", daysToKeep: 30))

        // there are 3 rows here
        let original = """
        188|action_14|/Users/kdeda/Desktop/026/011/029/003.txt|
        189|action_13|/Users/kdeda/Desktop/008/022/014/023.txt
        190|action_13|/Users/kdeda/Desktop/026/027/014/001.txt
        """

        let originalData = original.data(using: .utf8) ?? Data()
        let originalSlice = ArraySlice<UInt8>(originalData)
        let lines = originalSlice.components(separatedBy: Data.newLineSeparatorByte)

        Log4swift[Self.self].info("lines: '\(lines.count)'")
        lines.forEach { slice in
            Log4swift[Self.self].info("line: \(String(decoding: slice, as: UTF8.self))")
        }
        #expect(lines.count == 3)

        let columns = lines[1].components(separatedBy: RowItem.separator)
        Log4swift[Self.self].info("columns: '\(columns.count)'")
        columns.forEach { slice in
            Log4swift[Self.self].info("column: \(String(decoding: slice, as: UTF8.self))")
        }
        #expect(columns.count == 3)
    }

    /**
     Create a bunch of random reference rows as [RowItem]
     Create a file with them, say '|' column separated and '\n' new line separated
     Create task that reads this file and creates the the derivedRows as [RowItem]

     Assert they are the same
     */
    @Test func testRowItemLines() async {
#if os(iOS)
#else
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/IDDSwift")
        Log4swift.configureCompactSettings()
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "IDDSwift", appSuffix: "", daysToKeep: 30))

        let filePathURL = URL(fileURLWithPath: "/tmp/testURLs.log")
        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")
        
        // create reference data
        let referenceRows = RowItem.generateRows(Int.random(in: 100 ..< 200))
            .sorted(by: { $0.rowID < $1.rowID })
        // create file
        // try? FileManager.default.removeItem(at: filePathURL)
        try? Data().write(to: filePathURL)
        referenceRows.forEach { row in
            let rowStrimg = row.textRow + "\n"
            filePathURL.append(data: rowStrimg.data(using: .utf8) ?? Data())
        }

        // read the file
        var derivedRows: [RowItem] = []
        await withTaskGroup(of: [RowItem].self) { group  in
            /// run the process in a task, when it completes we will finish the continuation
            group.addTask {
                guard let stream = try? filePathURL.readLines()
                else { return [] }
                
                var rv = [RowItem]()
                for await rows in stream {
                    rv.append(contentsOf: rows.compactMap(RowItem.init(bytes:)))
                }
                return rv
            }
            
            // Collect results
            for await rowsItems in group {
                derivedRows.append(contentsOf: rowsItems)
            }
        }

        derivedRows = derivedRows.sorted(by: { $0.rowID < $1.rowID })

        //        // deda debug
        //        derivedRows.forEach { row in
        //            let rowID = String(format: "%010d", row.rowID)
        //            Log4swift[Self.self].info("[\(rowID)] '\(row.textRow)'")
        //        }
        
        // Assert they are the same
        if let deltas = diff(referenceRows, derivedRows, format: .proportional) {
            Log4swift[Self.self].info("deltas: '\(deltas)'")
        }
        #expect(referenceRows == derivedRows)
        Log4swift[Self.self].dash("benchMark")

#endif
    }
}

