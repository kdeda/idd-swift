//
//  Channel.swift
//  WhatSize
//
//  Created by Klajd Deda on 3/26/24.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation
@preconcurrency import Combine

/**
 Yuck
 https://stackoverflow.com/questions/75776172/passthroughsubjects-asyncpublisher-values-property-not-producing-all-values
 */
public final class Channel<Output> where Output: Sendable {
    nonisolated(unsafe)
    private let subject = PassthroughSubject<Output, Never>()

    public init() {
    }

    @Sendable
    public func send(_ value: Output) {
        subject.send(value)
    }

    public func values() -> AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

extension Channel: Sendable {}

extension Channel: Equatable where Output: Equatable {
    public static func == (lhs: Channel<Output>, rhs: Channel<Output>) -> Bool {
        lhs === rhs
    }
}

#endif
