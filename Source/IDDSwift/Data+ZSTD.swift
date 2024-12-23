//
//  Data+ZSTD.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/6/21.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import ZSTDSwift

public extension Data {
    
    /**
     https://github.com/aperedera/SwiftZSTD
     the new supreme leader, twice if not thirce faster than zlibCompressed()
     these guys are 10 times slower https://github.com/tsolomko/SWCompression

     This is extremely fast nowdays

     Mac Studio M2 Ultra 2023
     2024-02-29 02:26:00.855 <11025> [I 16e3bd4] <Foundation.Data zlibCompressed>   in: '17,481,600' out: '5,920,087 bytes' in: '47.650 ms'
     2024-02-29 02:26:00.855 <11025> [I 16e3cf9] <Foundation.Data zlibCompressed>   in: '17,449,896' out: '5,893,207 bytes' in: '46.966 ms'
     2024-02-29 02:26:00.857 <11025> [I 16e3bcc] <Foundation.Data zlibCompressed>   in: '17,458,880' out: '5,898,466 bytes' in: '48.657 ms'
     */
    var zlibCompressed: Data {
        var rv = Data()
        // let startDate = Date.init()
        // defer {
        //     Log4swift[Self.self].info("in: '\(self.count.decimalFormatted)' out: '\(rv.count.decimalFormatted) bytes' completed in: '\(startDate.elapsedTime)'")
        // }

        let processor = ZSTDProcessor(useContext: true)

        do {
            rv = try processor.compressBuffer(self, compressionLevel: 2)
        } catch ZSTDError.libraryError(let errStr) {
            Log4swift[Self.self].error("Library error: \(errStr)")
        } catch ZSTDError.invalidCompressionLevel(let lvl) {
            Log4swift[Self.self].error("Invalid compression level: \(lvl)")
        } catch ZSTDError.decompressedSizeUnknown {
            Log4swift[Self.self].error("Unknown decompressed size")
        } catch {
            Log4swift[Self.self].error("Unknown error.")
        }
        
        //let rv = self.compress(withAlgorithm: .lzfse) ?? Data()
        //let rv = (self as NSData).zlibCompressed() as Data
        return rv
    }

    /**
     This is extremely fast nowdays

     Mac Studio M2 Ultra 2023
     2024-03-01 08:59:43.846 <39149> [I 1851366] <Foundation.Data zlibUncompressed>   in: '5,889,248' out: '17,461,240 bytes' in: '23.656 ms'
     2024-03-01 08:59:43.847 <39149> [I 1851367] <Foundation.Data zlibUncompressed>   in: '5,891,120' out: '17,464,688 bytes' in: '23.731 ms'
     */
    var zlibUncompressed: Data {
        var rv = Data()
        // let startDate = Date.init()
        // defer {
        //     Log4swift[Self.self].info("in: '\(self.count.decimalFormatted)' out: '\(rv.count.decimalFormatted) bytes' completed in: '\(startDate.elapsedTime)'")
        // }

        let processor = ZSTDProcessor(useContext: true)
        
        do {
            rv = try processor.decompressFrame(self)
        } catch ZSTDError.libraryError(let errStr) {
            Log4swift[Self.self].error("Library error: \(errStr)")
        } catch ZSTDError.invalidCompressionLevel(let lvl){
            Log4swift[Self.self].error("Invalid compression level: \(lvl)")
        } catch ZSTDError.decompressedSizeUnknown {
            Log4swift[Self.self].error("Unknown decompressed size")
        } catch {
            Log4swift[Self.self].error("Unknown error.")
        }
        
        //let rv = self.decompress(withAlgorithm: .lzfse) ?? Data()
        //let rv = (self as NSData).zlibUncompressed() as Data
        return rv
    }
}
