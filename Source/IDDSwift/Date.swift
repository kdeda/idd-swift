//
//  Date.swift
//  IDDSwift
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

public extension Date {
    static let defaultFormatter = DateFormatter.init(withFormatString: "yyyy-MM-dd HH:mm:ss.SSS Z", andPOSIXLocale: true)

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
        elapsedTimeInMilliseconds.with3Digits
    }

    func string(withFormat formatString: String) -> String {
        let dateFormatter = DateFormatter.init(withFormatString: formatString, andPOSIXLocale: true)
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

