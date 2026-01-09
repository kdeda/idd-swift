//
//  AsyncSequence+Collect.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

#if os(macOS)
import Foundation
import Log4swift

/**
 https://liudasbar.medium.com/the-new-world-of-swift-concurrency-a-deep-dive-into-async-await-actors-and-more-e03ee9a72450
 https://swiftonserver.com/advanced-async-sequences/

 https://stackoverflow.com/questions/73425713/swift-map-asyncstream-into-another-asyncstream
 */

extension AsyncStream {
    /// Collect elements from upstream in the time interval of waitForMilliseconds and bunches them.
    /// This helps the upstream handle arrays of elements every waitForMilliseconds rather than a complete deluge.
    ///
    /// - Parameter waitForMilliseconds: The number of milliseconds to wait before emitting.
    /// The waitForMilliseconds must be a sensible value say larger than 10ms.
    /// - Returns: Returns: A new AsyncStream of arrays of elements.
    public func collect(
        waitForMilliseconds: UInt
    ) -> AsyncStream<[Element]> where Element: Sendable {
        return AsyncStream<[Element]> { continuation in
            let buffer = ArrayActor<Element>()

            func drain() async {
                let batch = await buffer.popAll()
                if !batch.isEmpty {
                    continuation.yield(batch)
                }
            }

            // re-emit upstream after waiting for waitForMilliseconds
            let task1 = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: .nanoseconds(milliseconds: Int(waitForMilliseconds)))
                    await drain()
                }
            }

            let task2 = Task {
                // pile them in the buffer as fast as you can
                for await element in self {
                    await buffer.append(element)
                }

                await drain()
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task1.cancel()
                task2.cancel()
            }
        }
    }
}
#endif
