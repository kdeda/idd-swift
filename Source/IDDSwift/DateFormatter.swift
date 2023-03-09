//
//  DateFormatter.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/4/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

public extension DateFormatter {
    convenience init(withFormatString formatString: String, andPOSIXLocale posixLocale: Bool) {
        self.init()
        self.locale = Locale.init(identifier: "en_US_POSIX")
        self.dateFormat = formatString
        self.formatterBehavior = .behavior10_4
    }
}
