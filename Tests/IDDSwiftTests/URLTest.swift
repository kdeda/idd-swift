//
//  URLTest.swift
//  idd-swift
//
//  Created by Klajd Deda on 7/21/26.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Testing
import Foundation
import Log4swift
@testable import IDDSwift

struct URLTest {
    /**
     */
    @Test func testComponentsTo() {
        Log4swift.configureCompactSettings()
        // let logRootURL = URL.home.appendingPathComponent("Library/Logs/IDDSwift")
        // Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "IDDSwift", appSuffix: "", daysToKeep: 30))
        Log4swift.configure(fileLogConfig: nil)

        let filePathURL1 = URL.init(fileURLWithPath: "/")
        let tokens1 = filePathURL1.components(to: URL.init(fileURLWithPath: "/usr/share/zsh/5.9"))
        let expected1: [String] = [
            "usr",
            "share",
            "zsh",
            "5.9"
        ]
        Log4swift[Self.self].info("tokens1: './\(tokens1.joined(separator: "/"))'")
        #expect(tokens1 == expected1, "Please review case1")

        let filePathURL2 = URL.init(fileURLWithPath: "/Users/kdeda/Documents/_WhatSize/_Test/FolderChanges")
        let tokens2 = filePathURL2.components(to: URL.init(fileURLWithPath: "/Users/kdeda/Documents/_WhatSize/_Test/FolderChanges/file1.txt"))
        let expected2: [String] = [
            "FolderChanges",
            "file1.txt"
        ]
        Log4swift[Self.self].info("tokens2: './\(tokens2.joined(separator: "/"))'")
        #expect(tokens2 == expected2, "Please review case2")

        let filePathURL3 = URL.init(fileURLWithPath: "/Users/kdeda/Documents/_WhatSize/_Test/FolderChanges")
        let tokens3 = filePathURL3.components(to: URL.init(fileURLWithPath: "/Users/kdeda/Documents/BackBlaze"))
        let expected3: [String] = []
        Log4swift[Self.self].info("tokens3: './\(tokens3.joined(separator: "/"))'")
        #expect(tokens3 == expected3, "Please review case3")
    }
}
