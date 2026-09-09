//
//  FileHandle.swift
//  idd-swift
//
//  Created by Klajd Deda on 1/11/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public extension FileHandle {
    /**
     timeOut in milliseconds
     Read from say standardInput without blocking
     ```
     Task {
         for await line in FileHandle.standardInput.readLineNonBlocking(100) {
             if line.lowercased() == "dump" {
                 print("Dumping")
                 let fileNames = popAll()
                 for file in fileNames {
                     print(file)
                 }
             }
             else if line.lowercased() == "exit" {
                 print("Exiting")
                 break
             }
         }
     }
     ```
     */
    func readLineNonBlocking(_ timeOut: Int = 100) -> AsyncStream<String> {
        AsyncStream { continuation in
#if canImport(Darwin) || canImport(Glibc)
            let fd = self.fileDescriptor

            // Set non-blocking
            let flags = fcntl(fd, F_GETFL, 0)
            _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
#endif

            let task = Task {
                while !Task.isCancelled {
                    // Try to read
#if canImport(Darwin) || canImport(Glibc)
                    var buffer = [UInt8](repeating: 0, count: 1024)
#if canImport(Darwin)
                    let bytesRead = Darwin.read(fd, &buffer, buffer.count)
#else
                    let bytesRead = Glibc.read(fd, &buffer, buffer.count)
#endif

                    if bytesRead > 0 {
                        if let input = String(bytes: buffer.prefix(bytesRead), encoding: .utf8) {
                            let line = input.trimmingCharacters(in: .whitespacesAndNewlines)

                            Log4swift[Self.self].info("received: '\(line)'")
                            continuation.yield(line)
                        }
                    }

                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: timeOut))
#else
                    // Windows' FileHandle has no fd/fcntl access, so we cannot poll
                    // non-blocking. Fall back to a blocking read of whatever is
                    // available, which will pause here until a line arrives.
                    let data = self.availableData

                    if !data.isEmpty,
                       let input = String(data: data, encoding: .utf8)
                    {
                        let line = input.trimmingCharacters(in: .whitespacesAndNewlines)

                        Log4swift[Self.self].info("received: '\(line)'")
                        continuation.yield(line)
                    } else {
                        try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: timeOut))
                    }
#endif
                }

                // let status = Task.isCancelled ? "was canceled" : "was completed in full"
                // Log4swift[Self.self].info("task: '\(status)'")
                continuation.finish()
            }

            continuation.onTermination = { _ in
                // Log4swift[Self.self].dash(function: "measureRootNode", "terminated: '\(rootNode.filePath)'")
                // Log4swift[Self.self].info(function: "measureRootNode", "terminated: '\(rootNode.filePath)'")
                task.cancel()
            }
        }
    }
}
