//
//  Int.swift
//  IDDSwift
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public extension Bool {
    /*
     * true, false orderedDescending
     * false, true orderedAscending
     */
    func compare(_ object: Bool) -> ComparisonResult {        
        if object == self {
            return ComparisonResult.orderedSame
        } else if !self && object {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }

    var hasChanged: String {
        self ? "'has changes ...'" : "'no changes ...'"
    }

}
