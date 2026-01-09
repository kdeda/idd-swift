//
//  FileChunk.swift
//  idd-swift
//
//  Created by Klajd Deda on 12/31/25.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation

struct FileChunk: ~Copyable {
    private let maxCount: Int
    // let _buffer: UnsafeMutablePointer<CChar>
    let _buffer: UnsafeMutablePointer<UInt8>

    init(maxCount: Int) {
        precondition(maxCount > 0)

        self.maxCount = maxCount
        _buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxCount)
        _buffer.initialize(repeating: 0, count: maxCount)
    }

    deinit {
        _buffer.deinitialize(count: maxCount)
        _buffer.deallocate()
    }

    var count: Int {
        strlen(_buffer)
    }

    var bytes: [UInt8] {
        let buffer = UnsafeBufferPointer(start: _buffer, count: count)
        return Array(buffer)
    }

    var asString: String {
        String(cString: _buffer)
    }
}
