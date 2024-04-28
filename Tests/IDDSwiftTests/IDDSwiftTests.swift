import XCTest
import Log4swift
import IDDSwift

final class IDDSwiftTests: XCTestCase {
    static var allTests = [
        ("testAsyncOutput", testAsyncOutput),
        ("testProcessFetchString", testProcessFetchString),
        ("testSH256", testSH256)
    ]

    static var logConfig = false

    override func setUp() async throws {
        guard Self.logConfig
        else { return }

        LoggingSystem.bootstrap { label in
            ConsoleHandler(label: label)
        }
        Self.logConfig = true
    }
    
    /**
     Creates a file where the asyncOutput will go
     touch /tmp/asyncOutput.log
     you can tail it
     tail -f /tmp/asyncOutput.log

     Creates the test file
     touch /tmp/test.log
     append to it
     echo "`date` 123 this is cool" >> /tmp/test.log^C
     echo "`date +"%Y-%m-%d %H:%M:%S"` magical shrums" >> /tmp/test.log
     echo "`date +"%Y-%m-%d %H:%M:%S"` magical shrums `uuidgen`" >> /tmp/test.log
     */
    func testAsyncOutput() async {
#if os(iOS)
#else
        let logFile = URL(fileURLWithPath: "/tmp/asyncOutput.log")
        let messageCount = 10
        var logReadContent: [String] = .init()
        var logWriteContent: [String] = .init()

        Log4swift[Self.self].info("-----")
        Log4swift[Self.self].info("Starting ...")

        try? FileManager.default.removeItem(at: logFile)
        try? "".write(to: logFile, atomically: true, encoding: .utf8)
        guard let fileHandle = try? FileHandle(forWritingTo: logFile)
        else {
            // make sure the file is there and available for writing
            XCTFail("Failed to create write handle on: '\(logFile.path)'", file: #file, line: #line)
            return
        }
        /**
         Listen to logFile and append lines into logFileContent
         */
        let process = Process(URL(fileURLWithPath: "/usr/bin/tail"), [
            "-f",
            logFile.path
        ])

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // read task, but do not wait more than 5 seconds
                for await output in process.asyncOutput(timeOut: 5) {
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
                        logReadContent.append(message.trimmingCharacters(in: .newlines))

                    case let .stderr(data):
                        let message = String(data: data, encoding: .utf8) ?? ""
                        logReadContent.append(message.trimmingCharacters(in: .newlines))
                    }
                }
            }
            group.addTask {
                // write task
                /**
                 We should be done in 10 * 1000, or 10 seconds
                 */
                await (0 ..< messageCount).asyncForEach { index in
                    let message = Date().stringWithDefaultFormat + " " + String(format: "%08d", index)

                    logWriteContent.append(message)
                    fileHandle.write(Data(message.utf8))
                    fileHandle.write(Data("\n".utf8))
                    
                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: 1000))
                }

                // https://forums.swift.org/t/the-problem-with-a-frozen-process-in-swift-process-class/39579/3
                // this does not work on linux
                process.terminate()
            }
        }

        XCTAssertEqual(logReadContent, logWriteContent)
#endif
    }

    /**
     Create a shell script
     touch /tmp/tmutil
     chmod +x /tmp/tmutil
     with these contents
     #!/bin/sh
     #
     #

     echo "Test 123, Test 123, Test 123"
     sleep 4
     exit 0
     */
    func testProcessFetchString() async {
#if os(macOS)
        // we want to log
        UserDefaults.standard.setValue("D", forKey: "IDDSwift.Process")

        let tmutilURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        // let tmutilURL = URL(fileURLWithPath: "/tmp/tmutil")

        //  /usr/bin/tmutil listbackups
        //  /usr/bin/tmutil machinedirectory
        //  /usr/bin/tmutil destinationinfo -X
        //  /usr/bin/tmutil uniquesize /Volumes/Vault/Backups.backupdb/macpro3000/2015-06-09-113054/Yosemite\ XP941/Users/kdeda/

        do {
            let processData = try Process.processData(taskURL: tmutilURL, arguments: ["machinedirectory"], timeOut: 3.0)

            Log4swift[Self.self].info("processData.stdout: '\(processData.stdOutString)'")
            Log4swift[Self.self].info("processData.stderr: '\(processData.stdErrorString)'")
        } catch {
            Log4swift[Self.self].info("processError.error: '\(error)'")
        }

        XCTAssert(true, "Failed to create write handle on")
        Log4swift[Self.self].info("Completed")
        Log4swift[Self.self].info("-----")
#endif
    }

    func testSH256() async {
#if os(macOS)
        let url = URL(fileURLWithPath: "/Users/kdeda/Desktop/Packages/WhatSize_8.0.8/WhatSize.tgz")
        let sha256 = url.sha256

        XCTAssertEqual(sha256, "DADF281E1F4141B5-5A23014632-9522057CE976-F3F5B9D2D369-68B0AF513EC086")
        Log4swift[Self.self].info("Completed")
        Log4swift[Self.self].info("-----")
#endif
    }
}
