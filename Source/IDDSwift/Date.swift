//
//  Date.swift
//  IDDSwift
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public extension Date {
    /**
     Be ware this is not UTC, which might be perfectly fine.
     Its default timeZone is the device’s local time zone.
     */
    static let defaultFormatter: DateFormatter = {
        let rv = DateFormatter.init(posixFormatString: "yyyy-MM-dd HH:mm:ss.SSS Z")
        return rv
    }()

    static func elapsedTime(for closure: (()-> Swift.Void)) -> String {
        let startDate = Date.init()
        closure()
        return startDate.elapsedTime
    }

    static func elapsedTime(from elapsedTimeInMilliseconds: Double) -> String {
        elapsedTimeInMilliseconds.with3Digits
    }

    // positive number if some time has elapsed since now
    //
    var elapsedTimeInMilliseconds: Double {
        -self.timeIntervalSinceNow * 1000.0
    }

    // positive number if some time has elapsed since now
    //
    var elapsedTimeInSeconds: Double {
        (-self.timeIntervalSinceNow)
    }

    var elapsedTime: String {
        elapsedTimeInMilliseconds.with3Digits + " ms"
    }

    func string(withFormat formatString: String) -> String {
        let dateFormatter = DateFormatter.init(posixFormatString: formatString)
        return dateFormatter.string(from: self)
    }

    var stringWithDefaultFormat: String {
        stringWithDateFormatter(Date.defaultFormatter)
    }

    func stringWithDateFormatter(_ dateFormatter: DateFormatter) -> String {
        dateFormatter.string(from: self)
    }

    // if numberOfDays is positive return date is us but numberOfDays in the future
    // if numberOfDays is negative return date is us but numberOfDays in the past
    //
    func date(shiftedByDays numberOfDays: Int) -> Date {
        Date(timeInterval: Double(numberOfDays * 24 * 3600), since: self)
    }
}

public extension String {
    var dateWithDefaultFormat: Date? {
        Date.defaultFormatter.date(from: self)
    }
}

