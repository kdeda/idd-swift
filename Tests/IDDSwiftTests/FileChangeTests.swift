import XCTest
import Log4swift
import Logging
import IDDSwift
// @testable import IDDSwiftTests

final class FileChangeTests: XCTestCase {
    func testExample() {
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
    
    override func setUp() async throws {
        LoggingSystem.bootstrap { label in
            ConsoleHandler(label: label)
        }
    }
    
    /**
     To terminate in a terminal window, rm filePath
     The filePath will be printed when you run this code
     You can also add to the file in terminal and the added values will print here
     */
    func testFileChanges() async -> Void {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AsyncSequence.txt")
        
        if fileURL.fileExist {
            try? FileManager.default.removeItem(at: fileURL)
        }
        // create file
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
        // the file is empty
        Log4swift[Self.self].info("listen: '\(fileURL.path)'")
        
        // this is what we will write to the file
        let writtenRows = (0 ..< 10).map { "row \($0)" }
        let wittenData = writtenRows.joined(separator: "")

        // write rows onto the file at random times on it's own task
        Task {
            await writtenRows.asyncForEach { row in
                fileURL.append(data: row.data(using: .utf8) ?? Data())
                let sleepInBetween = Int.random(in: (10 ..< 1000))
                try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * UInt64(sleepInBetween))
            }
            Log4swift[Self.self].info("wrote: '\(wittenData)'")
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // read the data on its own task
        let task = Task<Data, Never> {
            var readData = Data()
            
            // will wait 1.5 seconds before emitting
            for await fileChanges in fileURL.fileChanges().collect(waitForMilliseconds: 1500) {
                let bytes = fileChanges.reduce(into: Data()) { partialResult, nextItem in
                    switch nextItem {
                    case let .started(data): partialResult.append(data)
                    case let .added(data): partialResult.append(data)
                    case .fileDeleted:
                        Log4swift[Self.self].info("terminated")

                    }
                }
                
                if !bytes.isEmpty {
                    readData.append(bytes)

                    let chunk = String(data: bytes, encoding: .utf8) ?? ""
                    Log4swift[Self.self].info("received:\n\(chunk)")
                }
            }
            Log4swift[Self.self].info("terminated")
            return readData
        }
        
        let readData = String(data: await task.value, encoding: .utf8) ?? ""
        Log4swift[Self.self].info("read: '\(readData)'")

        // success if the reader got exactly what the writter put in there
        XCTAssertEqual(wittenData, readData)
    }
}
