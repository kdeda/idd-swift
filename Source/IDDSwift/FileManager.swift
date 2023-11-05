//
//  FileManager.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/25/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
#if os(macOS)
import Cocoa
#endif

public extension FileManager {
    private static var mountedVolumes = [String]()
    private static var mountedVolumesLastFetchDate = Date.distantPast
    private static var registerForWorkSpaceNotifications = false
#if os(macOS)
    private static let lock = NSRecursiveLock()
#endif

    /**
     it will return false if the file exists and we could not remove it
     */
    func removeItemIfExist(at pathURL: URL) -> Bool {
        do {
            if pathURL.fileExist {
                try FileManager.default.removeItem(at: pathURL)
            }
        } catch {
            Log4swift[Self.self].error("failed to remove: '\(pathURL.path)'")
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
            return false
        }
        return true
    }
    
    var hasFullDiskAccess: Bool {
        return hasFullDiskAccess(forHomeDirectory: URL.home)
    }

    /**
     This is a convenience helper to call in case you fail the hasFullDiskAccess test
     ```
     guard FileManager.default.hasFullDiskAccess
     else {
         FileManager.default.fullDiskAccessTips()
         return
     }
     ```
     */
    func hasFullDiskAccessTips() {
        let executable = Bundle.main.executableURL ?? URL(fileURLWithPath: "/tmp/this/should/not/happen")

        /**
         /usr/bin/codesign -vvv  /Users/kdeda/Library/Developer/Xcode/DerivedData/scripts-dfnvbbpqjqmrnoawwethnlsgeqvj/Build/Products/Debug/xchelper
         */
        Log4swift[Self.self].error(
            """
            
                --------------------------------
                Please enable Full Disk Access for this executable

                1) To avoid problems, make sure your binary is signed
                /usr/bin/codesign --verify --verbose \(executable.path)

                2) If NOT, force sign it
                /usr/bin/codesign --verbose --force --timestamp --options=runtime --strict --sign 'Developer ID Application: ID-DESIGN INC. (ME637H7ZM9)' \(executable.path)

                3) Add it to System Settings
                open x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles
                open \(executable.deletingLastPathComponent().path)
                and add  \(executable.lastPathComponent)  to the list of allowed binaries"
            
                4) Finally for some command line tools make sure Terminal is on the Full Disk Access list
                ----
            
            """
        )
    }

    // true if any of these files exist and are readable by the current app
    //
    func hasFullDiskAccess(forHomeDirectory homeDirectory: URL) -> Bool {
        let userFiles = [
            "/Library/Application Support/AddressBook",
            "/Library/Application Support/CallHistoryDB",
            "/Library/Application Support/CallHistoryTransactions",
            "/Library/Application Support/com.apple.TCC",
            "/Pictures/Photos Library.photoslibrary",
            "/Library/Application Support/MobileSync",
            "/Library/Calendars",
            "/Library/Caches/CloudKit/com.apple.Safari",
            "/Library/Containers/com.apple.iChat",
            "/Library/Containers/com.apple.mail",
            "/Library/Caches/com.apple.Safari",
            "/Library/Caches/com.apple.safaridavclient",
            "/Library/Containers/com.apple.Safari",
            "/Library/Cookies",
            "/Library/IdentityServices",
            "/Library/HomeKit",
            "/Library/Mail",
            "/Library/Messages",
            "/Library/Metadata/com.apple.IntelligentSuggestions",
            "/Library/Metadata/CoreSpotlight",
            "/Library/PersonalizationPortrait",
            "/Library/Safari",
            "/Library/Suggestions"
        ]
        
        let inaccessibleURLs = userFiles
            .map { homeDirectory.appendingPathComponent($0) }
            .filter { $0.fileExist }
            .filter { !$0.isReadable }
        let rv = inaccessibleURLs.isEmpty
        
        // Log4swift[Self.self].info("process: '\(ProcessInfo.processInfo.processName)' homeDirectory: '\(homeDirectory.path)' hasFullDiskAccess: '\(rv)'")
        if !rv {
            let inaccessiblePaths = inaccessibleURLs
                .map(\.path)
                .prefix(4)
                .joined(separator: "',\n\t'")
            Log4swift[Self.self].info("process: '\(ProcessInfo.processInfo.processName)' homeDirectory: '\(homeDirectory.path)' hasFullDiskAccess: '\(rv)'")
            Log4swift[Self.self].info("process: '\(ProcessInfo.processInfo.processName)' cantAccess: \n\t'\(inaccessiblePaths)'")
        }
        return rv
    }

    @discardableResult
    func createDirectoryIfMissing(at pathURL: URL) -> Bool {
        guard !pathURL.fileExist
        else { return true }
        
        do {
            try FileManager.default.createDirectory(at: pathURL, withIntermediateDirectories: true, attributes: nil)
            return pathURL.fileExist
        } catch {
            Log4swift[Self.self].error("failed to create: '\(pathURL.path)'")
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        return false
    }

    private func registerForWorkSpaceNotifications() {
#if os(macOS)
        guard !Self.registerForWorkSpaceNotifications
        else { return }
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didMountNotification(_:)), name: NSWorkspace.didMountNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didUnmountNotification(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        Self.registerForWorkSpaceNotifications = true
#endif
    }

#if os(macOS)
    @objc private func didMountNotification(_ notification: NSNotification) {
        Self.lock.withLock {
            Log4swift[Self.self].info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
            Self.mountedVolumesLastFetchDate = Date.distantPast
        }
    }
    
    @objc private func didUnmountNotification(_ notification: NSNotification) {
        Self.lock.withLock {
            Log4swift[Self.self].info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
            Self.mountedVolumesLastFetchDate = Date.distantPast
        }
    }
#endif

    /*
     * /dev
     * /home
     * /net
     * /Volumes/...
     */
    func mountedVolumes(_ refetch: Bool) -> [String] {
#if os(macOS)
        Self.lock.withLock {
            func fetchMountedVolumes() -> [String] {
                var statfs: UnsafeMutablePointer<statfs>?
                let count = Int(getmntinfo(&statfs, 0))

                func charPointerToString(_ pointer: UnsafePointer<Int8>) -> String {
                    return String(cString: UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self))
                }

                if let volumesArray = statfs, count > 0 {
                    return (0..<count).map { (index) -> String in
                        var volume = volumesArray[index]
                        let mountTo = charPointerToString(&volume.f_mntonname.0)
                        //    let mountFrom = charPointerToString(&volume.f_mntfromname.0)
                        //    let fileSystemType = charPointerToString(&volume.f_fstypename.0)
                        return mountTo
                    }
                    .sorted(by: >)
                }
                return [String]()
            }

            /**
             Even when refetch is true
             do not really fetch unless 5 seconds have elapsed since last fetch
             */
            guard refetch,
                  -Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000 > 1000 * 5
            else {
                // Log4swift[Self.self].info("cache: '\(-Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000)'")
                return Self.mountedVolumes }

            // Log4swift[Self.self].info("fetch: '\(-Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000)'")
            registerForWorkSpaceNotifications()
            Self.mountedVolumes = fetchMountedVolumes()
            Self.mountedVolumesLastFetchDate = Date()
            return Self.mountedVolumes
        }
#else
        return []
#endif
    }
    
    func isMountedVolume(_ basePath: String) -> Bool {
#if os(macOS)
        Self.lock.withLock {
            return Self.mountedVolumes.firstIndex(where: { $0 == basePath}) != nil
        }
#else
        return false
#endif
    }
}
