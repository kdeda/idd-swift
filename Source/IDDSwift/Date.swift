//
//  Date.swift
//  IDDSwift
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public extension Date {
    /**
     Beware this is not UTC, which might be perfectly fine.
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
        self.elapsedTimeInMilliseconds.elapsedTime
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

    func date(withFormat formatString: String) -> Date {
        let dateFormatter = DateFormatter.init(posixFormatString: formatString)
        return dateFormatter.date(from: self) ?? .distantPast
    }
}

public extension Double {
    /**
     For less than         `10` ms add the 3 digits,     ex: '9.32 msec'
     For less than        `100` ms add the 2 digits,     ex: '99.3 msec'
     For less than      `1_000` ms add the 3 digits,     ex: ' 999 msec'
     For less than    ` 10_000` ms switch to sec,        ex: ' 9.99 sec'
     For less than    `100_000` ms switch to sec,        ex: ' 99.9 sec'
     For less than  `1_000_000` ms switch to sec,        ex: '  999 sec'
     For less than `10_000_000` ms switch to sec,        ex: '9,999 sec'
     */
    var elapsedTime: String {
        if self < 10 {
            return self.with2Digits + " msec"             // '9.32 msec'
        } else if self < 100 {
            return self.with1Digits + " msec"             // '99.3 msec'
        } else if self < 1_000 {
            return "\(Int(self))" + " msec"               // ' 999 msec'
        } else if self < 10_000 {
            return (self / 1000).with2Digits + " sec"     // ' 9.99 sec'
        } else if self < 100_000 {
            return (self / 1000).with1Digits + " sec"     // ' 99.9 sec'
        } else if self < 1_000_000 {
            return "\(Int(self / 1000))" + " sec"         // '  999 sec'
        }
        return Int(self / 1000).decimalFormatted + " sec" // '9,999 sec'
    }
}
