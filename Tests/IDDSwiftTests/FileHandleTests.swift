//
//  FileHandleTests.swift
//  idd-swift
//
//  Created by Klajd Deda on 1/11/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Testing
import Foundation
import Log4swift
@testable import IDDSwift

struct FileHandleTests {
    /**
     */
    @Test func testReadLineWithTimeOut() async {
#if os(iOS)
#else
        Log4swift.configureCompactSettings()
        // let logRootURL = URL.home.appendingPathComponent("Library/Logs/IDDSwift")
        // Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "IDDSwift", appSuffix: "", daysToKeep: 30))
        Log4swift.configure(fileLogConfig: nil)

        // in mseconds
        let taskLength: UInt64 = 2_000
        // Will emulate some work
        func workerTask(id: Int, finishFirst: Bool) -> Task<Void, Never> {
            Task {
                var count = 0
                let iterations: UInt64 = 10 * UInt64.random(in: (5 ... 7))
                let sleep = finishFirst ? ((taskLength - 500) / iterations) : (taskLength / iterations)

                Log4swift[Self.self].info("task.\(id) started")
                while !Task.isCancelled {
                    // sleep for 250 milliseconds
                    try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * sleep)
                    count += 1
                    if count % 10 == 0 {
                        Log4swift[Self.self].info("task.\(id) processed \(count) iterations")
                    }
                    if count > iterations {
                        break
                    }
                }

                let status = Task.isCancelled ? "was canceled" : "was completed in full"
                Log4swift[Self.self].info("task.\(id): '\(status)'")
            }
        }

        // which of the 3 threads will finish first
        // finish means they will send the last message before all others
        //
        let finishIndex = Int.random(in: (1 ... 3))
        let task1: Task<Void, Never> = workerTask(id: 1, finishFirst: finishIndex == 1)
        let task2: Task<Void, Never> = workerTask(id: 2, finishFirst: finishIndex == 2)

        let pipe = Pipe()
        let fileHandle = {
            /**
             to emulate sending data to the other size
             in a real app this should be
             ```
             let fileHandle = FileHandle.standardInput
             ```
             */
            pipe.fileHandleForReading
        }()

        let task3: Task<Void, Never> = {
            Task {
                let id = "3"

                for await line in fileHandle.readLineNonBlocking(100) {
                    if line.lowercased() == "exit" {
                        Log4swift[Self.self].info("Exiting")
                        break
                    }
                }

                let status = Task.isCancelled ? "was canceled" : "was completed in full"
                Log4swift[Self.self].info("task.\(id): '\(status)'")
            }
        }()

        // Emulate sending input
        let task4: Task<Void, Never> = {
            Task {
                let finishFirst = finishIndex == 3
                let iterations: UInt64 = 2
                let sleep = finishFirst ? ((taskLength - 500) / iterations) : (taskLength / iterations)

                try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * sleep)
                var message = "fooBar"
                Log4swift[Self.self].info("send: \(message)")
                pipe.fileHandleForWriting.write("\(message)\n".data(using: .utf8) ?? Data())

                try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * sleep)
                message = "exit"
                pipe.fileHandleForWriting.write("\(message)\n".data(using: .utf8) ?? Data())
            }
        }()

        Log4swift[Self.self].dash("starting, finishIndex: '\(finishIndex)'")
        Log4swift[Self.self].info("starting, finishIndex: '\(finishIndex)'")
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await task1.value
                task2.cancel()
                task3.cancel()
            }
            group.addTask {
                await task2.value
                task1.cancel()
                task3.cancel()
            }
            group.addTask {
                await task3.value
                task1.cancel()
                task2.cancel()
            }
            group.addTask {
                await task4.value
            }
        }

        Log4swift[Self.self].dash("completed")
        Log4swift[Self.self].info("completed")
#endif
    }
}
