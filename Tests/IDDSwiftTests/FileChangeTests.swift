import XCTest
import Log4swift
import IDDSwift

@MainActor
final class FileChangeTests: XCTestCase {
//    static var allTests = [
//        ("testFileChanges", testFileChanges),
//    ]

    override func setUp() {
        super.setUp()

        Log4swift.configure(fileLogConfig: nil)

        // This happens on the DiskScanner Application.init
        //   // add -standardLog true to the arguments for the target, IDDFolderScan
        //   //
        //   let logRootURL = URL.home.appendingPathComponent("Library/Logs/DiskScannerTests")
        //   Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "DiskScannerTests", appSuffix: "", daysToKeep: 30))
        //
        //   Log4swift[""].info("")
        //   Log4swift[""].dash("\(Bundle.main.appVersion.shortDescription)")
        //   Log4swift[""].info("\(Bundle.main.appVersion.shortDescription)")
        //
        //   /// make sure we have full disk access
        //   guard FileManager.default.hasFullDiskAccess
        //   else {
        //       FileManager.default.hasFullDiskAccessTips()
        //       exit(0)
        //   }
        // Self.logConfig = true
    }

    /**
     Will create a temporary file
     Will start a task1 that writes to it
     Will start a task2 that reads at most every 1.5 second from it
     Will start a task3 that waits for 10 seconds and than kills task1, task2
     Will assert that we read what we wrote
     */
    func testFileChanges() async -> Void {
#if os(macOS)
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AsyncSequence.txt")

        // re-create the file
        FileManager.default.removeItemIfExist(at: fileURL)
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
        Log4swift[Self.self].info("listen: '\(fileURL.path)'")

        let writtenRows: ArrayActor<String> = .init()
        let readRows: ArrayActor<String> = .init()

        // write rows onto the file at random speed
        let task1 = Task {
            await (0 ..< 1000).asyncForEach { index in
                if !Task.isCancelled {
                    let stringRow = String(format: "row %04d", index)
                    await writtenRows.append(stringRow)
                    fileURL.append(data: (stringRow + "\n").data(using: .utf8) ?? Data())

                    // Log4swift[Self.self].info("   wrote: '\(stringRow)'")
                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: Int.random(in: (5 ..< 50))))
                }
            }

            let writtenCount = await writtenRows.count
            Log4swift[Self.self].info(" wrote: '\(writtenCount.decimalFormatted) rows'")
        }
        
        // read the data on its own task
        let task2 = Task {
            // will wait 1.5 seconds before emitting
            for await fileChanges in fileURL.fileChanges().collect(waitForMilliseconds: 1500) {
                let bytes = fileChanges.reduce(into: Data()) { partialResult, nextItem in
                    switch nextItem {
                    case let .started(data): partialResult.append(data)
                    case let .added(data):   partialResult.append(data)
                    case .fileDeleted:       Log4swift[Self.self].info("terminated")
                    }
                }
                
                if !bytes.isEmpty {
                    let chunk = String(data: bytes, encoding: .utf8) ?? ""
                    let rows = chunk.components(separatedBy: "\n").filter({ !$0.isEmpty })

                    await readRows.append(contentsOf: rows)
                    Log4swift[Self.self].info("  read: '\(rows.count.decimalFormatted)'")
                    // Log4swift[Self.self].info("received: '\(rows.joined(separator: "', '"))'")
                }
            }

            let readCount = await readRows.count
            Log4swift[Self.self].info("  read: '\(readCount.decimalFormatted) rows'")
        }

        // wait for 6 seconds and kill the listener
        let task3 = Task {
            try? await Task.sleep(nanoseconds: .nanoseconds(seconds: 6))
            task1.cancel()

            try? await Task.sleep(nanoseconds: .nanoseconds(seconds: 2))
            try? FileManager.default.removeItem(at: fileURL)

            // task2 should terminate on it's own
        }

        _ = await task3.value
        _ = await task2.value
        let writtenCount = await writtenRows.count
        let readCount = await readRows.count

        // success if the reader got exactly what the writter put in there
        XCTAssertEqual(writtenCount, readCount)
#endif
    }
}
