//
//  Array.swift
//  IDDSwift
//
//  Created by Klajd Deda on 12/26/19.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public extension Array {
    /**
     You can set values in items inside arrays in one line using key paths.
     Keeps the call sites easy to read.

     Usage:
     ```
     self.items = self.items
         .set(false, at: \.isOriginal)
         .set(true, at: \.isOriginal, where: { $0.id == entryID })
     ```
     */
    func set<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<Element, Value>,
        where closure: @escaping (Element) -> Bool
    ) -> [Element] {
        return self.reduce(into: []) { (result, next) in
            var newItem = next

            if closure(newItem) {
                newItem[keyPath: keyPath] = value
            }
            result.append(newItem)
        }
    }

    func set<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<Element, Value>
    ) -> [Element] {
        return self.set(value,
            at: keyPath,
            where: { _ in true }
        )
    }
}

public extension Array where Element: Equatable {
    func unique() -> Array {
        return reduce(Array()) { uniqueValues, element in
            uniqueValues.contains(element) ? uniqueValues : uniqueValues + [element]
        }
    }

    func split(batchSize: Int) -> [[Element]] {
        var rv: [[Element]] = []

        for idx in stride(from: 0, to: count, by: batchSize) {
            let upperBound = Swift.min(idx + batchSize, count)

            rv.append(Array(self[idx..<upperBound]))
        }
        return rv
    }

    // safe
    // https://www.hackingwithswift.com/example-code/language/how-to-make-array-access-safer-using-a-custom-subscript
    //
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return .none
        }

        return self[index]
    }
}
