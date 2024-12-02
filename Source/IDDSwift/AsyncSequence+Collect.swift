//
//  AsyncSequence+Collect.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

#if os(macOS)
import Foundation
import Log4swift

public extension AsyncSequence {
    /// Collect elements from an async sequence.
    ///
    /// - Parameter waitForMilliseconds: The number of milliseconds to wait before emitting.
    /// By default this is `1000` or one second. The waitForMilliseconds must be a non zero
    /// positive integer.
    /// - Returns: Returns: A new stream of array of all elements.
    @Sendable
    func collect(waitForMilliseconds: Int = 0) -> AsyncStream<[Element]> {
        AsyncStream { continuation in
            let buffer = ArrayActor<Element>()
            // let startDate = Date()

            // Log4swift[Self.self].info("waitForMilliseconds: '\(waitForMilliseconds) ms'")
            // Receive data updates in this task
            let task1 = Task {
                for try await element in self {
                    await buffer.append(element)
                }

                // once the real sequence ends
                // emitt the last batch and terminate all
                let batch = await buffer.popAll()

                // Log4swift[Self.self].info("batch.count: \(batch.count)")
                if !batch.isEmpty {
                    continuation.yield(batch)

                    // not really sure whay i had to inject a sleep here :-)
                    // maybe because we are going to terminate this stream
                    // and with it both task1, task2 defined here
                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: 50))
                }
                continuation.finish()
            }
            
            // re-emit upstream
            let task2 = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: waitForMilliseconds))
                    let batch = await buffer.popAll()

                    if !batch.isEmpty {
                        continuation.yield(batch)
                        //  } else {
                        //      // If we do not produce anything during the waitForMilliseconds
                        //      // We will not emitt
                        //      let elapsed = startDate.elapsedTimeInMilliseconds / Double(waitForMilliseconds)
                        //      Log4swift[Self.self].info("batch.count: \(batch.count): '\(Int(elapsed)) tick'")
                    }
                }
            }

            continuation.onTermination = { _ in
                // Log4swift[Self.self].info("terminated ...")
                task1.cancel()
                task2.cancel()
            }
        }
    }
}
#endif
