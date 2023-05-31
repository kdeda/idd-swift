//
//  EmailValidator.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/9/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

/**
 valid emails are now _@foo.com
 TODO: Fix me for linux
 Predicate strings and key-value coding are not supported in swift-corelibs-foundation
 */
public struct EmailValidator {
#if  os(iOS) || os(watchOS) || os(tvOS)
    private static let __firstpart = "[A-Z0-9a-z_]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
    private static let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
    private static let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
    private static let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)
#endif

    /**
     Validates an email address. Does not work on linux ...
     */
    public static func isValid(emailAddress: String) -> Bool {
        if emailAddress.isEmpty {
            return false
        }

        var isValid = true
#if  os(iOS) || os(watchOS) || os(tvOS)
        isValid = EmailValidator.__emailPredicate.evaluate(with: emailAddress)
#endif
        if !isValid {
            Log4swift[Self.self].error("invalid: '\(emailAddress)'")
        }
        return isValid
    }
}
