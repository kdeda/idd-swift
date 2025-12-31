//
//  Process+Async.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/28/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

#if os(iOS)
#else

import Foundation
import Log4swift

public extension Process {
    enum AsyncOutput {
        case error(ProcessError)
        case terminated(Process.TerminationReason)
        case stdout(Data)
        case stderr(Data)
    }

    /// Helper class to wrap the Process and be cosher, Sendable
    /// I suspect the Apple folks will make the Process truly Sendable on a future release
    /// for now use the @unchecked
    private final class Helper: @unchecked Sendable {
        var process: Process
        var continuation: AsyncStream<Process.AsyncOutput>.Continuation
        var command: String = ""
        var taskDescription: String = ""
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        init(
            process: Process,
            continuation: AsyncStream<Process.AsyncOutput>.Continuation
        ) {
            self.process = process
            self.continuation = continuation

            command = process.executableURL?.path ?? ""
            taskDescription = "\(command + " " + (process.arguments ?? []).joined(separator: " "))"

            process.standardOutput = standardOutputPipe
            process.standardError = standardErrorPipe
            /// will stream the stdout.
            standardOutputPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
                let data = file.availableData
                if !data.isEmpty {
                    continuation.yield(.stdout(data))
                }
            }
            /// will stream the stderr.
            standardErrorPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
                let data = file.availableData
                if !data.isEmpty {
                    continuation.yield(.stderr(data))
                }
            }

            process.terminationHandler = { [weak self] process in
                do {
                    try self?.standardOutputPipe.fileHandleForReading.close()
                    try self?.standardErrorPipe.fileHandleForWriting.close()
                } catch {
                    Log4swift["IDDSwift.Process"].error("Unable to close pipe: '\(error.localizedDescription)'")
                }

                // we are called when the process is terminated, completed
                // we are called on a completely different thread here
                self?.standardOutputPipe.fileHandleForReading.readabilityHandler = nil
                self?.standardErrorPipe.fileHandleForReading.readabilityHandler = nil

                Log4swift["IDDSwift.Process"].info("command: '\(self?.command ?? "")' terminated")
            }
        }

        /// Helper to run the process and wait till exit
        /// The exit will come, either naturally as the process ends, or will be generated
        /// when we kill it, during the forceTerminate(in:) step
        func runAndWaitUntilExit() -> Process.TerminationReason {
            do {
                try process.run()
                process.waitUntilExit()
                // Log4swift["IDDSwift.Process"].info("command: '\(command)' ended")
            } catch {
                Log4swift["IDDSwift.Process"].error("'\(taskDescription)' error: \(error)")
                continuation.yield(.error(.error(error.localizedDescription)))
            }

            standardOutputPipe.fileHandleForReading.closeFile()
            standardOutputPipe.fileHandleForWriting.closeFile()
            standardErrorPipe.fileHandleForReading.closeFile()
            standardErrorPipe.fileHandleForWriting.closeFile()
            return process.terminationReason
        }

        /// If timeOutInMilliseconds is greater that 0 we will wait in the background
        /// and kill the process
        func forceTerminate(in timeOutInMilliseconds: Int) async {
            guard timeOutInMilliseconds > 0
            else { return }

            Log4swift["IDDSwift.Process"].info("'\(taskDescription)' will give it '\(timeOutInMilliseconds) ms' to complete.")
            try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: timeOutInMilliseconds))
            guard !Task.isCancelled,
                  process.isRunning
            else {
                Log4swift["IDDSwift.Process"].info("'\(taskDescription)' appears to have completed on its own")
                return
            }
            Log4swift["IDDSwift.Process"].info("'\(taskDescription)' the '\(timeOutInMilliseconds) ms' are up and this process will be terminated immediately.")
            process.terminate()
            Process.killProcess(pid: Int(process.processIdentifier))
        }
    }

    /**
     Convenience. Create an instance of the Process class and than run it as an async stream by calling asyncOutput on it.

     This allows to serialize what you do with the output.
     Be aware that we will capture the process, stdout and stderr and pass them to the AsyncStream.
     */
    func asyncOutput(
        timeOut timeOutInSeconds: Double = 0
    ) -> AsyncStream<AsyncOutput> {
        AsyncStream(AsyncOutput.self) { continuation in
            guard let commandURL = self.executableURL,
                  commandURL.fileExist
            else {
                let command = self.executableURL?.path ?? ""
                continuation.yield(.error(.commandNotFound(command)))
                return
            }

            let helper = Helper(process: self, continuation: continuation)
            Log4swift["IDDSwift.Process"].info("\(helper.taskDescription)")

            let task = Task.detached {
                // run a few tasks here
                await withTaskGroup(of: Void.self) { group  in
                    /// run the process in a task, when it completes we will finish the continuation
                    group.addTask {
                        let reason = helper.runAndWaitUntilExit()

                        // debug
                        switch reason {
                        case .exit:           Log4swift["IDDSwift.Process"].debug("terminationReason: 'exit \(reason.rawValue)'")
                        case .uncaughtSignal: Log4swift["IDDSwift.Process"].debug("terminationReason: 'uncaughtSignal \(reason.rawValue)'")
                        @unknown default:     Log4swift["IDDSwift.Process"].debug("terminationReason: 'unknown \(reason.rawValue)'")
                        }
                        continuation.yield(.terminated(reason))
                        continuation.finish()
                    }

                    /// if we are asked to timeOutInSeconds, spawn another task and potentially kill/force
                    /// terminate the process
                    group.addTask {
                        await helper.forceTerminate(in: Int(timeOutInSeconds * 1_000))
                    }
                }
            }

            continuation.onTermination = { _ in
                Log4swift["IDDSwift.Process"].info("terminated ...")
                task.cancel()
            }
        }
    }

    static func killProcess(pid: Int) {
        guard pid > 0
        else {
            Log4swift[Self.self].error("pid: '\(pid)' should be a positive number")
            return
        }
        _ = Self.stdString(taskURL: URL(fileURLWithPath: "/bin/kill"), arguments: ["-9", "\(pid)"])
    }
}

#endif
