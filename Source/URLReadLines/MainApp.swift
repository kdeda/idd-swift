//
//  URLReadLines.swift
//  idd-swift
//
//  Created by Klajd Deda on 1/2/26.
//

import Foundation
import IDDSwift
import Log4swift

internal struct URLReadLinesImp {
    /**
    swift package clean

    # Build specific target, default is debug
    swift build --target URLReadLines
    swift build -c release --target URLReadLines

    # Run the executable
    swift run URLReadLines

    # Or run directly
    .build\debug\URLReadLines.exe
    .build\release\URLReadLines.exe

     ```
     find /Library/Backblaze.bzpkg/ -name "bz_done*0.dat" | sort | while read -r file; do cat $file >> /tmp/testBZDone.log; done
     find /Library/Backblaze.bzpkg/ -name "bz_done_202512??_0.dat" | sort | while read -r file; do cat $file >> /tmp/testBZDone.log; done
     ```
     */
    func testBzDoneReadLines() async {
#if os(iOS)
#else
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/URLReadLines")
        Log4swift.configureCompactSettings()
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "URLReadLines", appSuffix: "", daysToKeep: 30))
        // Log4swift.configure(fileLogConfig: nil)

#if os(Windows)
        // let filePathURL = URL(fileURLWithPath: "Z:\\Desktop\\testBZDone.log")
        // let filePathURL = URL(fileURLWithPath: "Z:\\Desktop\\bz_done_20260101_0.dat")
        let filePathURL = URL(fileURLWithPath: "C:\\Users\\kdeda\\Developer\\testBZDone.log")
#else
        let filePathURL = URL.home.appendingPathComponent("Desktop/testBZDone.log")
#endif
        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")

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

                Log4swift[Self.self].info("read: '\(totalBytes.decimalFormatted) bytes' '\(chunkCounts.decimalFormatted) chunks', in: '\(startDate.elapsedTime)'")
            }
        }

        Log4swift[Self.self].dash("benchMark")
#endif
    }
}

@main
struct MainApp {
    static func main() async {
        let worker = URLReadLinesImp()
        await worker.testBzDoneReadLines()
    }
}
