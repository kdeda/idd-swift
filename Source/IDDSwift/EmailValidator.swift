//
//  EmailValidator.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/9/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

/**
 valid emails are now _@foo.com
 TODO: Fix me for linux
 Predicate strings and key-value coding are not supported in swift-corelibs-foundation
 */
public struct EmailValidator {
#if  os(macOS)
    private static let __firstpart = "[A-Z0-9a-z_]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
    private static let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
    private static let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
    // FIXME: this does not work for emails like `john+doe_1968@google.com`
    // private static let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)
#endif

    /**
     Validates an email address. Does not work on linux ...
     */
    public static func isValid(emailAddress: String) -> Bool {
        if emailAddress.isEmpty {
            return false
        }

        let tokens = emailAddress.components(separatedBy: "@")
        let isValid = tokens.count == 2
//#if  os(macOS)
//        isValid = EmailValidator.__emailPredicate.evaluate(with: emailAddress)
//        if !isValid {
//            Log4swift[Self.self].error("invalid: '\(emailAddress)'")
//        }
//#endif
        return isValid
    }
}
