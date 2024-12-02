//
//  Sequence.swift
//  IDDSwift
//
//  Created by Klajd Deda on 1/7/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

/**
 Async helpers.
 */
public extension Sequence {
    func asyncMap<T>(
        _ transform: @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncCompactMap<T>(
        _ transform: @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }

        return values
    }

    func asyncForEach(
        _ operation: @Sendable (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
