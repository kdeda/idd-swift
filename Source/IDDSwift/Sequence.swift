//
//  Sequence.swift
//  IDDSwift
//
//  Created by Klajd Deda on 1/7/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation

/**
 Async helpers.
 */
public extension Sequence {
    func asyncMap<T>(
        _ operation: @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(operation(element))
        }

        return values
    }

    func asyncCompactMap<T>(
        _ operation: @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let value = try await operation(element) {
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
