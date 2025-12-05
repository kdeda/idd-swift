//
//  ArraySlice+Extensions.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/15/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

extension ArraySlice where Element == UInt8 {
    /**
     In debug mode Self.components(separatedBy:includeLast:handle:) can be really slow
     Just add -ArraySlice.isDebugBuild true to use a faster version
     */
    static let isDebugBuild = UserDefaults.standard.bool(forKey: "ArraySlice.isDebugBuild")

    /**
     To debug add -Swift.ArraySlice<Swift.UInt8> D to the argument lines
     */
    static let isDebugLog = Log4swift[Self.self].isDebug

    /**
     If includeLast is false it will return the reminder
     Otherwise it will return empty reminder
     */
    public func components(
        separatedBy separator: UInt8 = Data.newLineSeparatorByte,
        includeLast: Bool = false,
        _ handle: (_ lineData: ArraySlice<UInt8>) -> Void
    ) -> ArraySlice<UInt8> {
        guard !Self.isDebugBuild
        else {
            let separator_ = Data([separator])
            
            let rv = self.componentsDebug(separatedBy: separator_, includeLast: includeLast, handle)
            return rv
        }
        
        guard !self.isEmpty
        else { return ArraySlice<UInt8>() }
        
        var currentIndex = startIndex
        var count = self.count
        
        if Self.isDebugLog {
            Log4swift[Self.self].debug("starting: [\(String(0).leftPadding(to: 4)) ... \(String(count).leftPadding(to: 4))] string: '\(String(decoding: self, as: UTF8.self))'")
        }
        for (offset_, byte) in self.enumerated() {
            let offset = startIndex + offset_
            
            //  if debug {
            //      Log4swift[Self.self].info("consumed: [\(String(offset).leftPadding(to: 4))] char: '\(String(decoding: [byte], as: UTF8.self))'")
            //  }
            if byte == separator {
                let lineData = self[currentIndex ..< offset]
                
                if Self.isDebugLog {
                    Log4swift[Self.self].debug("consumed: [\(String(currentIndex).leftPadding(to: 4)) ... \(String(offset).leftPadding(to: 4))] left: '\(count.decimalFormatted) bytes' string: '\(String(decoding: lineData, as: UTF8.self))'")
                }
                currentIndex = offset
                currentIndex += 1 // ignore the separator
                count -= lineData.count
                
                if !lineData.isEmpty {
                    handle(lineData)
                }
            }
        }
        
        if Self.isDebugLog {
            Log4swift[Self.self].debug("reminder: [\(String(currentIndex).leftPadding(to: 4)) ... \(String(self.count).leftPadding(to: 4))], string: '\(String(decoding: suffix(from: currentIndex), as: UTF8.self))'")
        }
        guard currentIndex < self.endIndex
        else { return ArraySlice<UInt8>() }
        if includeLast {
            // let string = String(decoding: suffix(from: currentIndex), as: UTF8.self)
            handle(suffix(from: currentIndex))
            return ArraySlice<UInt8>()
        }
        return suffix(from: currentIndex)
    }
    
    /**
     For DEBUG ONLY
     Much Slower than the above in release mode, but ok in debug builds
     */
    private func componentsDebug(
        separatedBy separator: Data,
        includeLast: Bool = false,
        _ handle: (_ lineData: ArraySlice<UInt8>) -> Void
    ) -> ArraySlice<UInt8> {
        guard !self.isEmpty
        else { return ArraySlice<UInt8>() }
        var data = Data(self)
        
        while true {
            if let range = data.range(of: separator) {
                // Convert complete line (excluding the delimiter) to a string:
                let lineData = data.subdata(in: 0 ..< range.lowerBound)
                
                if !lineData.isEmpty {
                    handle(ArraySlice([UInt8](lineData)))
                }
                
                // Remove line (and the delimiter) from the buffer:
                data.removeSubrange(0 ..< range.upperBound)
            } else {
                break
            }
        }
        
        guard !data.isEmpty
        else { return ArraySlice<UInt8>() }
        
        if includeLast {
            // Remove line (and the delimiter) from the buffer:
            handle(ArraySlice([UInt8](data)))
            return ArraySlice<UInt8>()
        }
        
        return ArraySlice([UInt8](data))
    }

    /**
     Will include the last token as well
     */
    public func components(separatedBy separator: UInt8 = Data.newLineSeparatorByte) -> [ArraySlice<UInt8>] {
        guard !self.isEmpty
        else { return [] }
        var rv = [ArraySlice<UInt8>]()
        let debug = false
        
        // ignore the return
        rv.reserveCapacity(16)
        _ = components(separatedBy: separator, includeLast: true) { lineData in
            rv.append(lineData)
        }
        
        if Self.isDebugLog {
            Log4swift[Self.self].debug("'\(rv.map({ String(decoding: $0, as: UTF8.self) }).joined(separator: "', '"))'")
        }
        return rv
    }
}
