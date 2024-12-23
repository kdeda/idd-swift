//
//  DateFormatter.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/4/17.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public extension DateFormatter {
    convenience init(posixFormatString formatString: String) {
        self.init()
        self.locale = Locale.init(identifier: "en_US_POSIX")
        self.dateFormat = formatString
    }
}
