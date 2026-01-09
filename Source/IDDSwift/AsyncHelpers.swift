//
//  AsyncHelpers.swift
//  IDDSwift
//
//  Created by Klajd Deda on 10/2/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

/**
 From Mike Laster, September 2023
 We were talking about the risk of mixing old legacy loc/unlock code called inside an async context
 There might be some issues to it.

 I always run with LIBDISPATCH\_COOPERATIVE\_POOL\_STRICT=1 under Xcode
 That forces the cooperative pool to only have a single thread, so if anything blocks it you see a deadlock immediately
 */

public func inAsyncContext() -> Bool {
    withUnsafeCurrentTask { $0 != nil }
}

/**
 If you want to flag stuff that you definitely never want called from an async context
 */
public func prohibitAsyncContext(functionName: String = #function) {
    guard inAsyncContext() == false else {
#if DEVELOPMENT_BUILD
        fatalError("\"\(functionName)\" is not allowed to be called from an asynchronous context!")
#else
        Log4swift["ASYNC"].error("\"\(functionName)\" is not allowed to be called from an asynchronous context!")
        return
#endif
    }
}

/**
 If you need to call legacy code that blocks the calling thread:

 Basically have a private serial queue and run all the dangerous stuff on it, not in the concurrency pool
 And use checked throwing continuations to safely wait for the result
 */
private let unsafeBlockingQueue = DispatchQueue(label: "com.id-design.unsafeBlocking", autoreleaseFrequency: .workItem)

/**
 Bridging function to allow calling async unsafe code from an async context.
 This should be a temporary crutch until the underlying code is rewritten to be non-blocking.
 */
public func unsafeBlocking<T>(_ unsafeBlockingBlock: @Sendable @escaping () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        unsafeBlockingQueue.async {
            continuation.resume(with: Result { try unsafeBlockingBlock() })
        }
    }
}

/**
 And the other way — you are in pre-async code but you need a value from the async world..
 */

//// Synchronously obtain a value from an asynchronous context without blocking the concurrent subsystem
//@available(*, noasync, message: "Not safe to call from an async context! -- rdar://97526323 (Audit for async safety)")
//// swiftlint:disable:next attributes
//public func unsafeFromAsyncTask<T>(_ block: @escaping @Sendable () async throws -> T) throws -> T {
//    // prohibitAsyncContext()
//
//    let retValue = UnsafeSendableBox<T>()
//    let caughtError = UnsafeSendableBox<Error?>()
//    let dispatchGroup = DispatchGroup()
//
//    dispatchGroup.enter()
//    Task {
//        defer { dispatchGroup.leave() }
//        do {
//            retValue.contents = try await block()
//        } catch {
//            caughtError.contents = error
//        }
//    }
//
//    dispatchGroup.wait()
//
//    if let unboxedError = caughtError.contents,
//        let error = unboxedError {
//        throw error
//    }
//
//    // swiftlint:disable:next force_unwrapping
//    return retValue.contents!
//}
//
//public final class UnsafeSendableBox<T>: @unchecked Sendable {
//    public var contents: T?
//
//    public init() {}
//}
