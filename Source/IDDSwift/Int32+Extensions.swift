//
//  Int32+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 1/5/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(ucrt)
import ucrt
#endif

public extension Int32 {
    var strerror: String {
#if os(Windows)
        var buffer = [Int8](repeating: 0, count: 256)
        buffer.withUnsafeMutableBufferPointer { ptr in
            _ = strerror_s(ptr.baseAddress, ptr.count, self)
        }
        return String(cString: buffer)
#else
        String(cString: Foundation.strerror(self))
#endif
    }
}
