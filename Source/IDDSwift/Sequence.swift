//
//  Sequence.swift
//  IDDSwift
//
//  Created by Klajd Deda on 1/7/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

extension Sequence {
    public func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    public func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
