//
//  URLReadLines.swift
//  idd-swift
//
//  Created by Klajd Deda on 11/15/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import XCTest
import Log4swift
import IDDSwift
import CustomDump

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

@MainActor
final class URLReadLines: XCTestCase {
    override func setUp() {
        super.setUp()

        Log4swift.configure(fileLogConfig: nil)
    }

    /**
     Create a bunch of random reference rows as [RowItem]
     Create a file with them, say '|' column separated and '\n' new line separated
     Create task that reads this file and creates the the derivedRows as [RowItem]
     
     Assert they are the same
     */
    func testReaLines() async {
#if os(iOS)
#else
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
        XCTAssert(referenceRows == derivedRows)
        Log4swift[Self.self].dash("benchMark")

#endif
    }
}

