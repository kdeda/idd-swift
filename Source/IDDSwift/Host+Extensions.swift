//
//  Host+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/11/24.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation

public extension Host {
    static var ipAddress: String {
        return "127.0.0.1"
    }

    static var currentHostName: String {
        return Host.current().name ?? "unknown"
    }

    static var serialNumber: String {
        IOService.serialNumber
    }
}

#endif
