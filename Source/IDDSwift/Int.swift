//
//  Int.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public extension Int {
    static let decimalFormatter: NumberFormatter = {
        let rv = NumberFormatter()
        
        rv.numberStyle = .decimal
        rv.locale = Locale.current
        return rv
    }()

    nonisolated(unsafe)
    static let compactFormater: ByteCountFormatter = {
        let rv = ByteCountFormatter()
        
        rv.countStyle = .file
        rv.zeroPadsFractionDigits = true
        return rv
    }()

    func compare(_ object: Int) -> ComparisonResult {
        let diff = self - object
        
        if diff == 0 {
            return ComparisonResult.orderedSame
        } else if diff > 0 {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }
    
    func roundedBy(_ round: Int) -> Int {
        let rv = Double(self) / Double(round)
        let rv_ = rv.rounded(.towardZero)
        
        return Int(rv_) * round
    }

    var decimalFormatted: String {
        return Int.decimalFormatter.string(from: self as NSNumber)!
    }
    
    var compactFormatted: String {
//        let foo = 220987608541
//        let foo1 = foo.compactFormattedV2
//        let foo2 = Int.compactFormater.string(fromByteCount: Int64(foo))
//
//        var rv = compactFormattedV2
//        var old = Int.compactFormater.string(fromByteCount: Int64(self))
//
//        if old != rv {
//            return Int.compactFormater.string(fromByteCount: Int64(self))
//        }
//        return rv
        return Int.compactFormater.string(fromByteCount: Int64(self))
    }
}

public extension Int64 {
    var decimalFormatted: String {
        return Int.decimalFormatter.string(from: self as NSNumber)!
    }
    
    var compactFormatted: String {
        return Int.compactFormater.string(fromByteCount: self)
    }
    
    func compare(_ object: Int64) -> ComparisonResult {
        let diff = self - object
        
        if diff == 0 {
            return ComparisonResult.orderedSame
        } else if diff > 0 {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }
    
    private static let fileSizeTypes = ["bytes", "KB", "MB", "GB", "TB", "PB", "XX"]

    var compactFormattedV2: String {
        let oneKB: Int64 = 1000

        if (self < oneKB) {
            if self > 99 {
                // only '888'
                return String(self)
            }
            // but '99 bytes'
            return "\(self) bytes"
        }
        
        var fileSizeTypeIndex = 0
        var reminder: Int64 = 0
        var fileSize = self

        while fileSize > oneKB {
            let  newFileSize = fileSize / oneKB

            fileSizeTypeIndex += 1
            reminder = fileSize - (newFileSize * oneKB)
            fileSize = newFileSize
        }

        reminder = (reminder * 10) / oneKB
        if (reminder > 0) {
            // round up the reminder if the fileSize is less than 3 digits
            // ie: 13.5 -> 13.5
            // ie: 135.5 -> 136
            //
            if fileSize > 99 {
                if reminder > 5 {
                    fileSize += 1
                    if fileSize > 950 {
                        fileSize = 1
                        fileSizeTypeIndex += 1
                    }
                }
                reminder = 0
            }
        }
        if fileSize > 950 {
            fileSize = 1
            fileSizeTypeIndex += 1
        }
        if fileSizeTypeIndex > (Self.fileSizeTypes.count - 2) {
            fileSizeTypeIndex = Self.fileSizeTypes.count - 1
        }
        if reminder > 0 {
            return "\(fileSize).\(reminder) \(Self.fileSizeTypes[fileSizeTypeIndex])"
        }
        return "\(fileSize) \(Self.fileSizeTypes[fileSizeTypeIndex])"
    }
    
    // From one of the profile tests, decimalFormatted was taking .5 seconds
    // this new imp, brings it down to .175
    //
    var decimalFormattedV2: String {
        let isNegative = (self < 0)
        let string = String(isNegative ? -self : self)
        var reverseIndex = string.count - 1
        var chars = [Character]()
        
        chars.reserveCapacity(string.count + string.count / 3)
        string.forEach { (char) in
            chars.append(char)
            if reverseIndex > 0 && (reverseIndex % 3) == 0 {
                chars.append(Character(","))
            }
            reverseIndex -= 1
        }

        (isNegative) ? chars.insert(Character("-"), at: 0) : ()
        return String(chars)
    }
}

public extension UInt64 {
    var decimalFormatted: String {
        return Int.decimalFormatter.string(from: self as NSNumber)!
    }

    var compactFormatted: String {
        return Int.compactFormater.string(fromByteCount: Int64(self))
    }
    
    func compare(_ object: UInt64) -> ComparisonResult {
        let diff = self - object
        
        if diff == 0 {
            return ComparisonResult.orderedSame
        } else if diff > 0 {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }
}

public enum Radix: Int {
    case base10 = 10
    case base16 = 16
}

public extension Int64 {
    private static let isDebug = {
        Log4swift[Self.self].isDebug
    }()
    
    fileprivate static func parse(_ bytes: ArraySlice<UInt8>, _ radix: Radix = .base10) -> Self? {
        guard !bytes.isEmpty
        else { return nil }

        var result: Int64 = 0
        let radix_ = Int64(radix.rawValue)
        var isNegative = false
        // due to how memory is managed by this type (this is more like a pointer)
        // the bytes.startIndex will not always be zero but say 49
        var startIndex = bytes.startIndex
        // bytes.count will represent the size, say 1
        var begin = 0

        // Check for sign
        if bytes[startIndex] == 45 { // ASCII '-'
            isNegative = true
            startIndex += 1
            begin = 1
        } else if bytes[startIndex] == 43 { // ASCII '+'
            startIndex += 1
            begin = 1
        }

        //        // deda debug
        //        bytes.enumerated().forEach { element in
        //            Log4swift[Self.self].info("char['\(startIndex + element.offset)']")
        //        }
        // self.count will represent the size, say 1
        for i in begin ..< bytes.count {
            // we start at begin and than grab the char at startIndex or 49
            let byte = bytes[startIndex + i]
            var digit: Int64 = 0

            // Check if it's a digit (ASCII '0' = 48, '9' = 57), (ASCII 'A' = 65, 'F' = 70), (ASCII 'a' = 97, 'f' = 102)
            if (byte >= 48 && byte <= 57) { // (ASCII '0' = 48, '9' = 57)
                digit = Int64(byte - 48)
            }
            else if (radix == .base16 && byte >= 65 && byte <= 70) { // (ASCII 'A' = 65, 'F' = 70)
                digit = Int64(byte - 65 + 10)
            }
            else if (radix == .base16 && byte >= 97 && byte <= 102) { // (ASCII 'a' = 97, 'f' = 102)
                digit = Int64(byte - 97 + 10)
            }
            else {
                // Invalid character
                // Do we want to see these ?
                // this code can be used in high performance situations and we might not want to display these
                if isDebug {
                    Log4swift[Self.self].debug("invalid char[\(i)]: \(String(decoding: bytes, as: UTF8.self))")
                }
                return nil
            }

            result = result * radix_ + digit
        }

        //        let string = String(decoding: bytes, as: UTF8.self)
        //        let expected = Int(string, radix: 16) ?? 0
        //        if expected != result {
        //            Log4swift[Self.self].error("string: '\(string)', intValue: '\(expected)', result: '\(result)'")
        //        }
        return isNegative ? -result : result
    }

    /**
     For now only radix 10 is implemented
     "3964" -> 3964
     */
    init?(_ bytes: ArraySlice<UInt8>, radix: Radix = .base10) {
        guard let parsed = Int64.parse(bytes, radix)
        else { return nil }

        self = parsed
    }

    init?(_ bytes: [UInt8], radix: Radix = .base10) {
        guard let parsed = Int64.parse(bytes.suffix(from: 0), radix)
        else { return nil }

        self = parsed
    }
}

public extension Int {
    /**
     For now only radix 10 is implemented
     "3964" -> 3964
     */
    init?(_ bytes: ArraySlice<UInt8>, radix: Radix = .base10) {
        guard let parsed = Int64.parse(bytes, radix)
        else { return nil }

        self = Int(parsed)
    }

    init?(_ bytes: [UInt8], radix: Radix = .base10) {
        guard let parsed = Int64.parse(bytes.suffix(from: 0), radix)
        else { return nil }

        self = Int(parsed)
    }
}
