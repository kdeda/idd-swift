//
//  Process+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 8/24/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if os(iOS)
#else

import Foundation
import Log4swift

public extension Process {
    enum ProcessError: Error {
        case error(String)
        case commandNotFound(String)
        case fullDiskAccess
    }
    
    /**
     We have to make this a class since we will evenutally mutate the innards of
     and instance of this during append(stdout:) or append(stderr:) calls

     If this was a var swift will see the mutating func as mutating the declared
     var and that is not lock protected ...
     */
    final class ProcessData: @unchecked Sendable {
        public private(set) var stdout = Data()
        public private(set) var stderr = Data()
        private let lock = NSRecursiveLock()

        /**
         In some rare times converting to utf8 fails, on those cases use the stdout directly
         */
        public var stdOutString: String {
            let rv = String(data: stdout, encoding: .utf8) ?? "unknown"
            return rv.trimmingCharacters(in: CharacterSet.controlCharacters)  // remove last new line
        }

        /**
         In some rare times converting to utf8 fails, on those cases use the stderr directly
         */
        public var stdErrorString: String {
            let rv = String(data: stderr, encoding: .utf8) ?? "unknown"
            return rv.trimmingCharacters(in: CharacterSet.controlCharacters)  // remove last new line
        }
        
        public var stdString: String {
            stdOutString + "\n" + stdErrorString
        }

        @discardableResult
        public func append(stdout data: Data) -> Data {
            lock.withLock {
                if !data.isEmpty {
                    stdout.append(data)
                }
                return data
            }
        }

        @discardableResult
        public func append(stderr data: Data) -> Data {
            lock.withLock {
                if !data.isEmpty {
                    stderr.append(data)
                }
                return data
            }
        }
    }
    
    /// Initalize a process with the command and some args.
    ///
    /// - Parameters:
    ///   - launchURL: Sets the receiver’s executable.
    ///   - arguments: Sets the command arguments that should be used to launch the executable.
    convenience init(_ launchURL: URL, _ arguments: [String] = []) {
        self.init()
        self.executableURL = launchURL
        self.arguments = arguments
        self.currentDirectoryURL = URL.home
        self.environment = {
            var rv = ProcessInfo.processInfo.environment
            
            // http://www.promac.ru/book/Sams%20-%20Cocoa%20Programming/0672322307_ch24lev1sec2.html
            // all sort of problems with using an NSTask
            // if it leaks file handles than we are in trouble
            // it will fail afterwards with a stupid 'attempt to insert nil value'
            // Klajd Deda, October 28, 2008
            // https://stackoverflow.com/questions/55275078/objective-c-nstask-buffer-limitation
            // Klajd Deda, November 30, 2019
            //
            rv["NSUnbufferedIO"] = "YES"
            return rv
        }()
    }

    /**
     If all goes well, returns ProcessData
     If any problem happens throw ProcessError

     This code could fail due to Full Disk Access protection
     Make sure we hasFullDiskAccess returns true

     If the child task takes to long and is killed we still get any partial output from it
     Not sure if this can be a problem
     Maybe we should change this to throw if we force terminate the child task

     August 2023
     */
    func processData(
        timeOut timeOutInSeconds: Double = 0
    ) throws -> ProcessData {
        let logger = Log4swift["IDDSwift.Process"]
        let timeOutInMilliseconds = Int(timeOutInSeconds * 1_000)
        let command = self.executableURL?.path ?? ""
        let arguments = (self.arguments ?? []).joined(separator: " ")
        let taskDescription = "'\(command)' \(arguments)"

        logger.info("\(taskDescription)")
        guard URL(fileURLWithPath: command).fileExist
        else { throw ProcessError.commandNotFound(command) }

        let semaphore = DispatchSemaphore(value: 0)
        let processData = ProcessData()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        self.standardOutput = standardOutputPipe
        self.standardError = standardErrorPipe

        if timeOutInSeconds > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeOutInMilliseconds)) { [weak self] in
                // this will kill the child task if it's taking longer that timeOutInSeconds
                guard let self = self
                else { return }
                guard self.isRunning
                else {
                    logger.info("\(taskDescription) status: 'is not running any longer'")
                    return
                }
                logger.info("\(taskDescription) status: 'has timed out and will be terminated immediately'")
                // terminate nicely
                self.terminate()
                // kill the mf
                Process.killProcess(pid: Int(self.processIdentifier))

                let status = !self.isRunning ? "was found terminated" : "should have been terminated, but it seems to be hanging on, this should not happen ..."
                logger.info("\(taskDescription) status: '\(status)'")
            }
        }

        /**
         Encapsulate the logs or stdout/stderr from the child process in our logs.
         This can come handy when doing verbose type work.
         */
        standardOutputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
#if os(macOS)
            let data = processData.append(stdout: fileHandle.availableData)

            if logger.logLevel == .trace {
                let logMessage = (String(data: data, encoding: .utf8) ?? "unknown")
                    .trimmingCharacters(in: CharacterSet.controlCharacters)  // remove last new line

                logger.trace("stdout: \(logMessage)")
            }
#endif
        }
        standardErrorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
#if os(macOS)
            let data = processData.append(stderr: fileHandle.availableData)

            if logger.logLevel == .trace {
                logger.trace("stderr: \(data.logMessage)")
            }
#endif
        }

        self.terminationHandler = { process in
            // logger.info("\(command) terminated")

#if os(macOS)
            /**
             May 10, 2025
             We could be terminating really fast here with data still on the pipes.
             If so grab em before return.
             
             We had seen this in the past but was able to reproduce it and fix it thanks to
             ProcessTests.testHeavyProcessLoad
             */
            let stdout = standardOutputPipe.fileHandleForReading.availableData
            if stdout.count > 0 {
                let data = processData.append(stdout: stdout)
                if logger.logLevel == .trace {
                    logger.trace("\(command) standardOutputPipe: '\(stdout.count)'")
                    logger.trace("stdout: \(data.logMessage)")
                }
            }

            let stderr = standardErrorPipe.fileHandleForReading.availableData
            if stderr.count > 0 {
                let data = processData.append(stderr: stderr)
                if logger.logLevel == .trace {
                    logger.trace("\(command) standardErrorPipe: '\(stderr.count)'")
                    logger.trace("stderr: \(data.logMessage)")
                }
            }
#endif

            // we are called when the process is terminated, completed
            // we are called on a completely different thread here
            standardOutputPipe.fileHandleForReading.readabilityHandler = nil
            standardErrorPipe.fileHandleForReading.readabilityHandler = nil
            
            semaphore.signal()
        }

        do {
            try self.run()
            if timeOutInMilliseconds > 0 {
                // if we have a timeOutInSeconds, wait here for the timeout
                // or the command to terminate happily, adding a tinny bit to avoid collisions
                // if the command ends before the timeout we will exit out of here
                let timeOutInMilliseconds_ = timeOutInMilliseconds + 120

                logger.trace("\(taskDescription) status: 'waiting for: '\(timeOutInMilliseconds)''")
                _ = semaphore.wait(timeout: .now() + .milliseconds(timeOutInMilliseconds_))
            }
            // logger.info("\(command) ended")
        } catch {
            // TODO: Should we throw here !!!
            logger.error("\(taskDescription) error: \(error)")
        }
        
        if self.isRunning {
            // we want our tasks to complete normally.
            // we should run out of stuff to read if the task has ended.
            // or vice versa, since we are piped into the task
            // we should not come here
            // however we seem to hit this spot some times !!!
            // we will give the runtime a second to terminate
            //
            var waitForTermination = 0
            let maxWait = 2 * 3600
            // maximum 2 hour ...
            // if it takes longer than that kill it
            //
            
            while self.isRunning
                    && waitForTermination < maxWait {
                Thread.sleep(forTimeInterval: 0.1)
                waitForTermination += 1
                if waitForTermination % 20 == 0 {
                    logger.info("\(taskDescription) status: 'waiting for termination'")
                }
            }
            if self.isRunning {
                // the task should be terminated by now, but in case it is not we try to force termination
                // Klajd Deda, October 28, 2008
                //
                logger.error("\(taskDescription) status: 'has taken longer than the maxWait of '\(maxWait) seconds' and will be terminated right now'")
                self.terminate()
            }
        }
        
        standardOutputPipe.fileHandleForReading.closeFile()
        standardOutputPipe.fileHandleForWriting.closeFile()
        standardErrorPipe.fileHandleForReading.closeFile()
        standardErrorPipe.fileHandleForWriting.closeFile()
        return processData
    }
    
    /**
     Convenience
     In some rare times converting to utf8 fails, on those cases use the processData directly
     */
    func stdString(
        timeOut timeOutInSeconds: Double = 0
    ) -> String {
        do {
            let processData = try self.processData(timeOut: timeOutInSeconds)
            return processData.stdString
        } catch {
            return ""
        }
    }

    /**
     Will set the current dir for this instance.
     */
    func currentDir(_ to: URL) -> Self {
        self.currentDirectoryURL = to
        return self
    }

    /**
     Convenience
     */
    static func stdString(
        taskURL: URL,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) -> String {
        Process(taskURL, arguments)
            .stdString(timeOut: timeOutInSeconds)
    }

    /**
     Convenience
     */
    static func processData(
        taskURL: URL,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) throws -> ProcessData {
        try Process(taskURL, arguments)
            .processData(timeOut: timeOutInSeconds)
    }

}

fileprivate extension Data {
    /**
     Returns is as string for logging, remove last new line
     */
    var logMessage: String {
        (String(data: self, encoding: .utf8) ?? "unknown")
            .trimmingCharacters(in: CharacterSet.controlCharacters)
    }
}

#endif
