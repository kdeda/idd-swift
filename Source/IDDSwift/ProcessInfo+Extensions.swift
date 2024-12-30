//
//  ProcessInfo+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 12/7/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation
import Log4swift

// MARK: - ProcessInfo -

public extension ProcessInfo {
    static let isRunningInPreviewMode = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
}

#endif
