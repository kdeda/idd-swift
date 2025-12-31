//
//  Int32+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 1/5/26.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Darwin

public extension Int32 {
    var strerror: String {
        String(cString: Darwin.strerror(self))
    }
}

