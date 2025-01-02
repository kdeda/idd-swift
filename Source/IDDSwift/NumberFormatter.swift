//
//  NumberFormatter.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/16/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public extension NumberFormatter {
    static let formaterWith3digits: NumberFormatter = {
        let rv = NumberFormatter()
        
        rv.locale = Locale.init(identifier: "en_US")
        rv.numberStyle = .decimal
        rv.maximumFractionDigits = 3
        rv.minimumFractionDigits = 3
        return rv
    }()

    static let formaterWith2digits: NumberFormatter = {
        let rv = NumberFormatter()

        rv.locale = Locale.init(identifier: "en_US")
        rv.numberStyle = .decimal
        rv.maximumFractionDigits = 2
        rv.minimumFractionDigits = 2
        return rv
    }()

    static let formaterWith1digits: NumberFormatter = {
        let rv = NumberFormatter()

        rv.locale = Locale.init(identifier: "en_US")
        rv.numberStyle = .decimal
        rv.maximumFractionDigits = 1
        rv.minimumFractionDigits = 1
        return rv
    }()
}

/**
 Conveniences
 let number1 = 0.123456
 let cool1 = number1.with3Digits -> 0.123
 let number2 = 120.123456
 let cool2 = number2.with2Digits -> 120.12
 */
public extension Double {
    var with3Digits: String {
        return NumberFormatter.formaterWith3digits.string(from: self as NSNumber) ?? "0.196"
    }

    var with2Digits: String {
        return NumberFormatter.formaterWith2digits.string(from: self as NSNumber) ?? "0.19"
    }

    var with1Digits: String {
        return NumberFormatter.formaterWith1digits.string(from: self as NSNumber) ?? "0.1"
    }
}
