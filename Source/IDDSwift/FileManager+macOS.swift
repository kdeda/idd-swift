//
//  FileManager+macOS.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/3/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension FileManager {
    // will fail if aFilePath is unreadable due to permissions ...
    //
    func pathsFromVolumeRoot(_ fileURL: URL) -> [URL] {
        var currentURL = fileURL
        let currentUUID = currentURL.volumeUUID
        var rv = [currentURL]
        var crawlup = currentURL.path != "/"

        guard crawlup
        else { return rv }

        repeat {
            let parentURL = currentURL.deletingLastPathComponent()
            let parentUUID = currentURL.volumeUUID
            
            // IDDLogDebug(self, _cmd, @"parent.uuid: '%@', parent.filePath: '%@'", parentUUID, parentPath);
            if parentUUID != currentUUID {
                break
            }
            currentURL = parentURL
            rv.append(currentURL)
            crawlup = currentURL.path != "/"
        } while crawlup
        return rv
    }

    func volumeRootPath(_ fileURL: URL) -> URL {
        return pathsFromVolumeRoot(fileURL).last ?? URL(fileURLWithPath: "")
    }
    
    func pathsFromVolumeRoot(_ filePath: String) -> [String] {
        pathsFromVolumeRoot(URL(fileURLWithPath: filePath)).map(\.path)
    }
    
    func volumeRootPath(_ filePath: String) -> String {
        return pathsFromVolumeRoot(filePath).last ?? ""
    }
}
