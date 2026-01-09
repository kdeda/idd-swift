//
//  FileChange.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation

/**
 We could map more cases from DispatchSource.FileSystemEvent here
 */
public enum FileChange: Equatable, Sendable {
    case started(Data)
    case added(Data)
    case fileDeleted
}

public extension FileChange {
    // convenience
    var stringValue: String {
        switch self {
        case let .started(data): return String(data: data, encoding: .utf8) ?? ""
        case let .added(data): return String(data: data, encoding: .utf8) ?? ""
        case .fileDeleted: return ""
        }
    }
}

public extension Array where Element == FileChange {
    var started: FileChange? {
        self.first(where: {
            if case .started(_) = $0 {
                return true
            }
            return false
        })
    }
    
    var added: FileChange {
        let buffer = self.reduce(into: Data()) { partialResult, nextItem in
            switch nextItem {
            case .started: ()
            case let .added(data): partialResult.append(data)
            case .fileDeleted: ()
            }
        }
        return .added(buffer)
    }
}
