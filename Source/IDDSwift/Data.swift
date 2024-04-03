//
//  Data.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension Data {
    init(withURL url: URL) {
        do {
            try self.init(contentsOf: url)
        } catch {
            self.init()
            Log4swift[Self.self].error("error: '\(error.localizedDescription)' We will return empty data.")
        }
    }
    
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
            else { return }
        append(data)
    }
}
