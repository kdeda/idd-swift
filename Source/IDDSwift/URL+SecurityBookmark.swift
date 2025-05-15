//
//  URL+SecurityBookmark.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/16/17.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa

public extension URL {
    private var securityBookmarkKey: String {
        return "securityScope://".appending(self.path)
    }
    
    // https://developer.apple.com/library/content/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html
    // https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html
    // values per volume
    //
    var hasSecurityBookmark: Bool {
        get {
            let securityBookmarkKey = self.securityBookmarkKey
            var rv = false
            
            Log4swift[Self.self].info("key: '\(securityBookmarkKey)'")
            if let bookmarkData = UserDefaults.standard.data(forKey: securityBookmarkKey) {
                var isStale = false

                do {
                    let url = try URL.init(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                    
                    if url == self {
                        if isStale {
                            Log4swift[Self.self].error("stale bookmark: '\(securityBookmarkKey)'")
                        } else {
                            if url.startAccessingSecurityScopedResource() {
                                rv = true
                            } else {
                                Log4swift[Self.self].error("could not access: '\(securityBookmarkKey)'")
                            }
                        }
                    }
                } catch {
                    Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
                }
            }
            Log4swift[Self.self].info("value: '\(rv)' path: '\(self.path)'")
            return rv
        }
        set {
            let securityBookmarkKey = self.securityBookmarkKey
            
            UserDefaults.standard.removeObject(forKey: securityBookmarkKey)
            if newValue {
                do {
                    let bookmarkData = try self.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: securityBookmarkKey)
                } catch {
                    Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
                }
            }
            UserDefaults.standard.synchronize()
            Log4swift[Self.self].info("value: '\(newValue)' path: '\(self.path)'")
        }
    }

    /*
     * APPLE_STORE_BUILD
     * after talking to a steve guy at apple's app review unit
     * 408 862 3544
     * remove entitlements to movies, pictures, music, downloads
     * and default to users' home folder they will consider this
     */
    func requestSecurityBookmark() -> Bool {
        // this is old Objective-Swift code that should be lifted into the UI layer
        //
        Log4swift[Self.self].error("NOOP")
        return false

//        let format = "As part of Apple's sandboxing policy we need permission to access the folder '%@'\n\n" +
//            "We will present an Open Panel, preselecting the folder '%@'\n\n" +
//            "To grant permissions just click \"Open\"".localized
//
//        _ = NSAlert.modalAlert(withStyle: .warning,
//                               message: "Warning".localized,
//                               informative: String(format: format, self.path, self.path),
//                               buttons: ["OK"],
//                               toWindow: window)
//        let openPanel = NSOpenPanel()
//
//        openPanel.title = "Choose a file".localized
//        openPanel.allowsMultipleSelection = false
//        openPanel.allowedFileTypes = [kUTTypeFolder as String]
//        openPanel.canChooseDirectories = true
//        openPanel.canCreateDirectories = false
//        openPanel.canChooseFiles = false
//        openPanel.showsHiddenFiles = true
//        openPanel.directoryURL = self
//
//        repeat {
//            let result = openPanel.runModal()
//
//            if result == .cancel {
//                return false
//            }
//
//            if let panelURL = openPanel.url {
//                if panelURL == self {
//                    return true
//                } else {
//                    let format = "As part of Apple's sandboxing policy we need permission to access the folder '%@'".localized
//
//                    _ = NSAlert.modalAlert(withStyle: .warning,
//                                           message: "Warning".localized,
//                                           informative: String(format: format, self.path),
//                                           buttons: ["OK"],
//                                           toWindow: window)
//                    openPanel.directoryURL = self
//                }
//            }
//        } while true
    }

}

#endif
