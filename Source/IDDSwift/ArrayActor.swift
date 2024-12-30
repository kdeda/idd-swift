//
//  ArrayActor.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public final actor ArrayActor<Value: Sendable> {
    public private(set) var value = [Value]()

    public init(reserveCapacity: Int = 10_000) {
        value.reserveCapacity(reserveCapacity)
    }

    public func append(_ newValue: Value) {
        value.append(newValue)
    }

    public func append(contentsOf newValues: [Value]) {
        value.append(contentsOf: newValues)
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
