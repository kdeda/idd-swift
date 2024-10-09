//
//  NSWorkSpace.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/8/17.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

#if os(macOS)
import Cocoa
import Log4swift

public extension NSWorkspace {
    private static var notifyAbout_DS_Store_Files_once = true
    // https://apple.stackexchange.com/questions/299138/show-hidden-files-files-in-finder-except-ds-store/300210#300210
    //

    // MARK: - Class methods -
    
    private static var _majorOSVersion: Int = -1
    private static var _minorOSVersion: Int = -1
    
    private static func updateVersions() {
        if let versionInfo = NSDictionary.init(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist") {
            if let productVersion = versionInfo["ProductVersion"] as? String {
                var tokens = productVersion.components(separatedBy: ".")
                
                while tokens.count > 2 {
                    tokens.removeLast()
                }
                if tokens.count == 2 {
                    _majorOSVersion = Int(tokens[0]) ?? 0
                    _minorOSVersion = Int(tokens[1]) ?? 0
                }
            }
        }
    }
    
    static var majorOSVersion: Int = {
        if _majorOSVersion == -1 {
            updateVersions()
        }
        return _majorOSVersion
    }()

    static var minorOSVersion: Int = {
        if _minorOSVersion == -1 {
            updateVersions()
        }
        return _minorOSVersion
    }()

    // MARK: - Private methods -

    private var _showHiddenFilesInFinder: Bool {
        if let defaults = UserDefaults.standard.persistentDomain(forName: "com.apple.finder") {
            if let showAllFiles = defaults["AppleShowAllFiles"] as? String {
                return showAllFiles.uppercased() == "TRUE" || showAllFiles.uppercased() == "YES"
            }
        }
        return false
    }

    // MARK: - Instance methods -
    
    var showHiddenFilesInFinder: Bool {
        get {
            return _showHiddenFilesInFinder
        }
        set {
            if _showHiddenFilesInFinder != newValue {
                if var defaults = UserDefaults.standard.persistentDomain(forName: "com.apple.finder") {
                    defaults["AppleShowAllFiles"] = newValue ? "true" : "false"
                    UserDefaults.standard.setPersistentDomain(defaults, forName: "com.apple.finder")
                    UserDefaults.standard.synchronize()
                    // reboot Finder
                    //
                    _ = Process.stdString(taskURL: URL(fileURLWithPath: "/usr/bin/killall"), arguments: ["Finder"])
                }
            }
        }
    }

    // This is deprecated code
//    /*
//     * For certain files this will fail.
//     * for example all invisible files/folders starting with .
//     * [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil]
//     * Added mechanism for switching to PathFinder or some other app.
//     *
//     * We need to enable Finder to show hidden files.
//     * http://lifehacker.com/188892/show-hidden-files-in-finder
//     *
//     * defaults write com.apple.finder AppleShowAllFiles true
//     * defaults write com.apple.finder AppleShowAllFiles false
//     * killall Finder
//     */
//    public func reveal(inFinder pathURL: URL, inWindow window: NSWindow) {
//        Log4swift[Self.self].logger.info("path: '\(pathURL.path)'")
//
//        if pathURL.path.hasSuffix(".DS_Store") {
//            if (NSWorkspace.majorOSVersion == 10 && NSWorkspace.minorOSVersion >= 12) || (NSWorkspace.majorOSVersion == 11) {
//                if Self.notifyAbout_DS_Store_Files_once {
//                    Self.notifyAbout_DS_Store_Files_once = false
//
//                    NSAlert.attachAlert(
//                        withStyle: .warning,
//                        message: "Warning".localized,
//                        informative: "Unfortunately Apple has configured Finder to never show .DS_Store files.\n".localized,
//                        buttons: ["OK".localized],
//                        toWindow: window
//                    ) { _ in }
//                    return
//                }
//            }
//        }
//
//        if pathURL.hasHiddenComponents && !showHiddenFilesInFinder {
//            let message = "To reveal hidden files we need to configure Finder to show hidden files. Are you ok with that ?".localized
//            let responseCode = NSAlert.modalAlert(
//                withStyle: .warning,
//                message: "Warning".localized,
//                informative: message,
//                buttons: ["OK", "Cancel"],
//                toWindow: window
//            )
//
//            switch responseCode {
//            case .alertFirstButtonReturn:
//                self.showHiddenFilesInFinder = true
//                break
//            default:
//                Log4swift[Self.self].error("unmanaged returnCode: '\(responseCode)'")
//            }
//        }
//
//        if !pathURL.fileExist {
//            let format = "The file at: '%@' is not accessible or not longer exist.\n\nPlease refresh your measures.".localized
//
//            NSAlert.attachAlert(
//                withStyle: .warning,
//                message: "Warning".localized,
//                informative: String(format: format, pathURL.path),
//                buttons: ["OK".localized],
//                toWindow: window
//            ) { _ in }
//            return
//        }
//
//        /* this will probably default to Finder !!
//         * some people use PathFinder as a replacement.
//         */
//        if !self.selectFile(pathURL.path, inFileViewerRootedAtPath: "") {
//            // should not get here ...
//            //
//            Log4swift[Self.self].error("Could not select: '\(pathURL.path)'")
//        }
//    }
}

public extension Process {
    static func killProcess(bundleIdentifiers: [String]) {
        bundleIdentifiers.forEach(Self.killProcess(bundleIdentifier:))
    }

    static func killProcess(bundleIdentifier: String) {
        NSWorkspace.shared.runningApplications.forEach { (runningApplication) in
            if let runningBundleIdentifier = runningApplication.bundleIdentifier,
               runningBundleIdentifier == bundleIdentifier {
                let runningProcessIdentifier = runningApplication.processIdentifier
                
                if runningProcessIdentifier != ProcessInfo.processInfo.processIdentifier {
                    // don't kill ourselves
                    //
                    Log4swift[Self.self].info("terminate: '\(runningBundleIdentifier).\(runningProcessIdentifier)'")
                    runningApplication.terminate()
                    // give it a second to respond
                    Thread.sleep(forTimeInterval: 1.0)
                    // apple will fail to terminate if said app asks you to save data or something
                    // we don't really care at this poing and will force kill it
                    //
                    Self.killProcess(pid: Int(runningProcessIdentifier))
                }
            }
        }
    }
}

#endif
