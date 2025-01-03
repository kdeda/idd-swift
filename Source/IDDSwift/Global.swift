//
//  Global.swift
//  IDDSwift
//
//  Created by Klajd Deda on 7/3/18.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public struct Global {
    /**
     Might come handy if we want to put softwre up on AppStore
     */
    public static var isAppStoreBuild: Bool {
        var rv = false
#if APPLE_STORE_BUILD
        rv = true
#else
#endif // APPLE_STORE_BUILD
        return rv
    }
}
