import XCTest
import Log4swift
import Logging
import IDDSwift
// @testable import IDDSwiftTests

final class IDDSwiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(IDDCommons().text, "Hello, World!")
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
     Create a test file
     touch /tmp/test.log
     append to it
     echo "`date` 123 this is cool" >> /tmp/test.log^C
     echo "`date +"%Y-%m-%d %H:%M:%S"` magical shrums" >> /tmp/test.log
     */
    func testProcessOutput() async {
        let process = Process(URL(fileURLWithPath: "/usr/bin/tail"), [
            "-f",
            "/tmp/test.log"
        ])
//        let process = Process(URL(fileURLWithPath: "/usr/bin/grep"), [
//            "Magical Shrums",
//            "/tmp/test.log"
//        ])
        
        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")
        for await output in process.asyncOutput(timeOut: 60) {
            switch output {
            case let .error(error):
                Log4swift[Self.self].error("output: \(error)")
                
            case let .terminated(reason):
                Log4swift[Self.self].info("-----")
                switch reason {
                case .exit:
                    Log4swift[Self.self].info("terminated: 'exit \(reason.rawValue)' usually a normal process termination")
                case .uncaughtSignal:
                    Log4swift[Self.self].info("terminated: 'uncaughtSignal \(reason.rawValue)' most likely the process got killed")
                @unknown default:
                    Log4swift[Self.self].info("terminated: 'unknown \(reason.rawValue)'")
                }
                Log4swift[Self.self].info("-----")

            case let .stdout(data):
                let message = String(data: data, encoding: .utf8) ?? ""
                fputs(message, stdout)
                // Log4swift[Self.self].info("stdout: \(message)")
                
            case let .stderr(data):
                let message = String(data: data, encoding: .utf8) ?? ""
                fputs(message, stdout)
                // Log4swift[Self.self].error("stderr: \(message)")
            }
        }
        Log4swift[Self.self].info("Terminated")
        Log4swift[Self.self].info("-----")
    }
}
