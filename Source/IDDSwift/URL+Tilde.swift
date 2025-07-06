//
//  URL+Tilde.swift
//  IDDSwift
//
//  Created by Klajd Deda on 10/22/22.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public extension URL {
    /// Expanding tilde in URL
    ///
    /// ```
    /// +--------+----------------------------------------------------+
    /// | Input  |  ~/Documents/git.id-design.com/whatsize7           |
    /// | Input  | /~/Documents/git.id-design.com/whatsize7           |
    /// +--------+----------------------------------------------------+
    ///     v
    /// +--------+----------------------------------------------------+
    /// | Output | /Users/kdeda/Documents/git.id-design.com/whatsize7 |
    /// +--------+----------------------------------------------------+
    /// ```
    /// - Precondition: The URL should be a file url or a string url that starts with `~/` or `/~/`.
    /// If the URL is empty or starts with the FileManager.default.homeDirectoryForCurrentUser.path return self.
    /// - Returns: The `URL` if we'r able to expand the ~ into a full URL, or `nil` if we'r unable do so
    ///
    /// Does nothing on windows systems
    var expandingTilde: URL? {
#if os(macOS) || os(Linux)
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        var components = self.pathComponents

        /**
         for some reason if we create a url from a path as such
         let filePath = "~/Developer/git.id-design.com/whatsize7/WhatSize/WhatSize.entitlements"
         let fileURL = URL.init(filePath: filePath).expandingTilde

         the self.pathComponents will have a lot of other components ...
         ["/, Users, kdeda, Developer, build, Debug, ~, Developer, git.id-design.com, whatsize7, WhatSize, WhatSize.entitlements"]

         the first token til the `~` are actually plucked from the executable that it runnning the code, in this case `/Users/kdeda/Developer/build/Debug/xchelper`

         so we should discard all before the `~`
         */
        guard let index = components.firstIndex(where: { $0 == "~" })
        else {
            // no `~` found
            // make sure it is returned back as file:/// schema
            // this should not be a problem, but it will catch those rare cases
            // when some one creates a file url from string
            return URL.init(fileURLWithPath: self.path)
        }

        (0 ... index).forEach { _ in
            components.remove(at: 0)
        }
        components.insert(homePath, at: 0)
        return URL.init(fileURLWithPath: components.joined(separator: "/"))
#else
        return nil
#endif
    }
}

