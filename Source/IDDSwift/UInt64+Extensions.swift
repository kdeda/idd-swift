//
//  UInt64+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 8/24/21.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public extension UInt64 {
    fileprivate static let NSEC_PER_MSEC: UInt64 = 1_000_000

    static func nanoseconds(milliseconds: Int) -> Self {
        Self.NSEC_PER_MSEC * UInt64(milliseconds)
    }

    static func nanoseconds(seconds: Int) -> Self {
        Self.NSEC_PER_MSEC * UInt64(seconds) * 1000
    }
}
