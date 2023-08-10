//
//  ArrayActor.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

public final actor ArrayActor<Value: Sendable> where Value: Equatable {
    public private(set) var value = [Value]()

    public init(reserveCapacity: Int = 10_000) {
        value.reserveCapacity(reserveCapacity)
    }

    /**
     Overwrite the isolated value with a new value.

     - Parameter newValue: The value to replace the current isolated value with.
     */
    public func append(_ newValue: Value) {
        value.append(newValue)
    }

    public func append(contentsOf newValues: [Value]) {
        value.append(contentsOf: newValues)
    }

    public func remove(_ existing: Value) {
        value.removeAll(where: { $0 == existing })
    }

    /**
     Pop all and return.
     */
    public func popAll() -> [Value] {
        let rv = value
        value.removeAll()
        return rv
    }

    /**
     Convenience.
     */
    public var count: Int {
        value.count
    }
}
