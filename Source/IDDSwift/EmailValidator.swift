//
//  EmailValidator.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/9/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

/**
 valid emails are now _@foo.com
 */
public struct EmailValidator {
    private static let __firstpart = "[A-Z0-9a-z_]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
    private static let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
    private static let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
    private static let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)

    public static func isValid(emailAddress: String) -> Bool {
        if emailAddress.isEmpty {
            return false
        }
        return EmailValidator.__emailPredicate.evaluate(with: emailAddress)
    }
}
