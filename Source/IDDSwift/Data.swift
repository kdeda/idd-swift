//
//  Data.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension Data {
    /**
     Allows me to quietly create data from a file path
     Even if the file path does not exist
     */
    init(withURL url: URL) {
        do {
            if url.fileExist {
                try self.init(contentsOf: url)
            } else {
                self.init()
                Log4swift[Self.self].info("filePath: '\(url.path)' was missing, will return empty data.")
            }
        } catch {
            self.init()
            Log4swift[Self.self].error("error: '\(error.localizedDescription)' will return empty data.")
        }
    }
    
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
            else { return }
        append(data)
    }
}
