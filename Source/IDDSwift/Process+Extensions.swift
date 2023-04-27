//
//  Process+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 8/24/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)
import Foundation
import Log4swift

public extension Process {
    enum ProcessError: Error {
        case error(String)
        case stdError(String)
        case commandNotFound(String)
        case fullDiskAccess
    }
    
    struct ProcessData {
        public var output = Data()
        public var error = Data()
        
        public var outputString: String {
            String(data: output, encoding: .utf8) ?? "unknown"
        }
        
        public var errorString: String {
            String(data: error, encoding: .utf8) ?? "unknown"
        }
        
        public var allString: String {
            let dictionary = [
                "outputString": outputString,
                "errorString": errorString
            ]
            let coder: JSONEncoder = {
                let rv = JSONEncoder()
                
                rv.outputFormatting = .prettyPrinted
                return rv
            }()
            let data = (try? coder.encode(dictionary)) ?? Data()
            let string = String(data: data, encoding: .utf8) ?? ""
            
            Log4swift["IDDSwift.Process"].debug("\(string)")
            return string
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
        self.currentDirectoryPath = NSHomeDirectory()
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
     This code will fail due to security protections in the mac
     Make sure we hasFullDiskAccess returns true
     */
    func fetchData(
        timeOut timeOutInSeconds: Double = 0
    ) -> Result<ProcessData, ProcessError> {
        let timeOutInMilliseconds = Int(timeOutInSeconds * 1_000)
        let command = self.executableURL?.path ?? ""
        let logger = Log4swift["IDDSwift.Process"]

        guard URL(fileURLWithPath: command).fileExist
        else { return .failure(.commandNotFound(command)) }

        let semaphore = DispatchSemaphore(value: 0)
        var processData = ProcessData()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        self.standardOutput = standardOutputPipe
        self.standardError = standardErrorPipe

        // if (IDDLogDebugLevel(self)) IDDLogDebug(self, _cmd, @"%@ \"%@\"", command, [arguments componentsJoinedByString:@"\" \""]);
        let taskDescription = "\(command + " " + (self.arguments ?? []).joined(separator: " "))"
        logger.debug("\(taskDescription)")
        if timeOutInSeconds > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeOutInMilliseconds)) { [weak self] in
                guard let self = self
                else { return }
                guard self.isRunning
                else {
                    logger.info("'\(taskDescription)' is not running any longer")
                    return
                }
                logger.info("'\(taskDescription)' will be terminated immediately")
                self.terminate()
                Process.killProcess(pid: Int(self.processIdentifier))
                logger.info("'\(taskDescription)' should be terminated now.")
                logger.info("'\(taskDescription)' self.isRunning: \(self.isRunning ? "YES" : "NO")")
            }
        }

        /**
         Encapsulate the logs or stdout/stderr from the child process in our logs.
         This can come handy when doing verbose type work.
         */
        standardOutputPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
#if os(macOS)
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
#endif
            let data = file.availableData
            
            // easy peasy in debug mode we will be more verbose with child output
            // otherwise it will be hidden but accumulated in the processData buffer
            if logger.isDebug {
                let logMessage = (String(data: data, encoding: .utf8) ?? "unknown")
                    .trimmingCharacters(in: CharacterSet.controlCharacters)  // remove last new line

                logger.debug("\(logMessage)")
                // for currentAppender in logger.appenders {
                //     currentAppender.performLog(logMessage, level: .Info, info: LogInfoDictionary())
                // }
            }
            processData.output.append(data)
        }
        standardErrorPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
#if os(macOS)
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
#endif
            let data = file.availableData
            
            // easy peasy in debug mode we will be more verbose with child output
            // otherwise it will be hidden but accumulated in the processData buffer
            if logger.isDebug {
                let logMessage = (String(data: data, encoding: .utf8) ?? "unknown")
                    .trimmingCharacters(in: CharacterSet.controlCharacters)  // remove last new line
                
                logger.debug("\(logMessage)")
                // for currentAppender in logger.appenders {
                //     currentAppender.performLog(logMessage, level: .Info, info: LogInfoDictionary())
                // }
            }
            processData.error.append(data)
        }

        self.terminationHandler = { process in
            // we are called when the process is terminated, completed
            // we are called on a completely different thread here
            standardOutputPipe.fileHandleForReading.readabilityHandler = nil
            standardErrorPipe.fileHandleForReading.readabilityHandler = nil
            
            // Log4swift["IDDSwift.Process"].info("command: '\(command)' terminated")
            semaphore.signal()
        }

        do {
            try self.run()
            if timeOutInMilliseconds > 0 {
                // if we have a timeOutInSeconds, wait here for the timeout
                // or the command to terminate happily, adding a
                let timeOutInMilliseconds_ = timeOutInMilliseconds + 120
                _ = semaphore.wait(timeout: .now() + .milliseconds(timeOutInMilliseconds_))
            }
            // Log4swift["IDDSwift.Process"].info("command: '\(command)' ended")
        } catch {
            logger.error("'\(taskDescription)' error: \(error)")
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
                    Log4swift["IDDSwift.Process"].info("command: '\(command)' waiting for termination")
                }
            }
            if self.isRunning {
                // the task should be terminated by now, but in case it is not we try to force termination
                // Klajd Deda, October 28, 2008
                //
                Log4swift["IDDSwift.Process"].error("We have taken longer than the maxWait of '\(maxWait) seconds' and will terminate this task now.")
                Log4swift["IDDSwift.Process"].error("The task '\(command)' is still running !!!")
                self.terminate()
            }
        }
        
        standardOutputPipe.fileHandleForReading.closeFile()
        standardOutputPipe.fileHandleForWriting.closeFile()
        standardErrorPipe.fileHandleForReading.closeFile()
        standardErrorPipe.fileHandleForWriting.closeFile()
        return .success(processData)
    }
    
    /**
     Convenience
     */
    static func fetchData(
        taskURL: URL,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) -> Result<ProcessData, ProcessError> {
        Log4swift["IDDSwift.Process"].info("\(taskURL.path) \(arguments.joined(separator: " "))")

        return Process(taskURL, arguments).fetchData(timeOut: timeOutInSeconds)
    }

    static func fetchString(
        taskURL: URL,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) -> String {
        Log4swift["IDDSwift.Process"].info("\(taskURL.path) \(arguments.joined(separator: " "))")

        let result = Process(taskURL, arguments)
            .fetchData(timeOut: timeOutInSeconds)
            .map { $0.outputString }
        
        return (try? result.get()) ?? ""
    }
}

public extension Result where Success == Process.ProcessData, Failure == Process.ProcessError {
    func allString() -> Result<String, Process.ProcessError> {
        flatMap { processData -> Result<String, Process.ProcessError> in
            return .success(processData.allString)
        }
    }
}
#endif
