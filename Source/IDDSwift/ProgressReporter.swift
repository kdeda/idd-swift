//
//  ProgressReporter.swift
//  IDDSwift
//
//  Created by Klajd Deda on 05/31/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation

/**
 We want to create a class that models a rate-limited progress reporter.
 The outside world should be able to modify the state at any time using `withValue {}` and
 call `report(milliseconds: Int = 100)` at any time
 However we want to report no more often than milliseconds interval

 Some times depending on the value are are reporting on we want to reset it to a new value
 when we executeReport
 Say we collect a bunch of items into an array and when we executeReport we want to start a new empty array
 In that case the newValueAfterExecuteReport should be a func that returns a new empty value
 */
public actor ProgressReporter<T: Sendable> {
    public private(set) var value: T

    /// we might want to zero our state after executeReport()
    private var newValueAfterExecuteReport: (() -> T)?

    /// This should be a number in milliseconds ie: 250 for 250 ms
    private let interval: Int

    /// Track absolute time in milliseconds using system uptime seconds
    private var lastReportInstant: Int
    private let continuation: AsyncStream<T>.Continuation

    public init(
        value: T,
        newValueAfterExecuteReport: (() -> T)? = .none,
        // Defaulting to 100 milliseconds
        interval: Int = 100,
        continuation: AsyncStream<T>.Continuation
    ) {
        self.value = value
        self.newValueAfterExecuteReport = newValueAfterExecuteReport
        self.interval = interval
        self.lastReportInstant = Int(ProcessInfo.processInfo.systemUptime * 1000.0)
        self.continuation = continuation
    }

    /// Pass a closure that safely mutates the internal storage
    public func withValue(_ body: (inout T) -> Void) {
        body(&value)
    }

    private func executeReport() {
        continuation.yield(value)

        if let newValue = newValueAfterExecuteReport {
            // only if
            value = newValue()
        }
    }

    public func reportNow() {
        lastReportInstant = Int(ProcessInfo.processInfo.systemUptime * 1000.0)
        executeReport()
    }

    public func report() {
        // Fix 3: Read current system uptime directly
        let now = Int(ProcessInfo.processInfo.systemUptime * 1000.0)

        if now - lastReportInstant < interval {
            return // Too soon — drop this report
        }

        lastReportInstant = now
        executeReport()
    }
}
