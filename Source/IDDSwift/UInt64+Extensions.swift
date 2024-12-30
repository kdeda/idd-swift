//
//  UInt64+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 8/24/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

/**
 Helpers to be used with Task.sleep(nanoseconds:)
 Which we should get rid off when we get rid of macOS 13 and older
 */
public extension UInt64 {
    fileprivate static let NSEC_PER_MSEC: UInt64 = 1_000_000

    /**
     Return nanoseconds from milliseconds
     */
    static func nanoseconds(milliseconds: Int) -> Self {
        Self.NSEC_PER_MSEC * UInt64(milliseconds)
    }

    /**
     Return nanoseconds from seconds
     */
    static func nanoseconds(seconds: Int) -> Self {
        Self.NSEC_PER_MSEC * UInt64(seconds) * 1000
    }
}
