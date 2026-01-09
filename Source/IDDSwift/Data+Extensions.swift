//
//  Data+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/15/25.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

extension Data {
    public static let newLineSeparator: Character = "\n"
    public static let newLineSeparatorByte: UInt8 = 10 // lineSeparator.asciiValue!
    
    public static let tabSeparator = CharacterSet(charactersIn: "\t")
    public static let tabSeparatorByte: UInt8 = 9 // tabSeparator.asciiValue!
    
    public static let pipeSeparator = CharacterSet(charactersIn: "\t")
    public static let pipeSeparatorByte: UInt8 = 9 // tabSeparator.asciiValue!

    /**
     Will include the last token as well
     */
    public func components(separatedBy separator: UInt8 = Self.newLineSeparatorByte) -> [ArraySlice<UInt8>] {
        guard !self.isEmpty
        else { return [] }
        let bytes = ArraySlice<UInt8>(self)
        var rv = [ArraySlice<UInt8>]()

        // ignore the return
        rv.reserveCapacity(16)
        _ = bytes.components(separatedBy: separator, includeLast: true) { (lineData: ArraySlice<UInt8>) in
            rv.append(lineData)
        }
        
        return rv
    }
}
