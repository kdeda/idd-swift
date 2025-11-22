//
//  URL+ReadLines.swift
//  IDDSwift
//
//  Created by Klajd Deda on 11/15/25.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

enum ReadLinesError: Error {
    case filePathMissing(URL)
    case incorrectDelimiter(String)
}

extension URL {
    /**
     Emmiting an array of lines at a time allows performance improvements ergonomics as well as low memory usage
     sicne we will read at most bufferSize = 256KB at a time
     This code will operate under utf8 contitions,
     We will emitt the butes for each row, upstream one can decide to do whatever with those bytes
     
     This code is very fast almost as fast as reading the bytes
     
     For now only the '\n' is supported as delimiter
     We should add support for '\r' as well in the near future
     */
    public func readLines(
        bufferSize: Int = 1024 * 128 * 2,
        recreateParsedFile: Bool = false
    ) throws -> AsyncStream<[ArraySlice<UInt8>]> {
        guard FileManager.default.fileExists(atPath: self.path)
        else {
            throw ReadLinesError.filePathMissing(self)
        }
        
        let delimiter = Data.newLineSeparatorByte
        let fileName = self.lastPathComponent
        let fileHandle1: FileHandle? = {
            if recreateParsedFile {
                /**
                 to debug parsing we can write back the lines we parse to a new file beside the original
                 the new file will have `_copy` at the end
                 we can than compare them to the byte level
                 diff -c `self.path` `self.path + "_copy"`
                 to see the differences
                 */
                let fileCopy = self.deletingLastPathComponent().appendingPathComponent(fileName + "_copy")
                FileManager.default.removeItemIfExist(at: fileCopy)
                try? "".write(to: fileCopy, atomically: true, encoding: .utf8)
                return FileHandle(forWritingAtPath: fileCopy.path)
            }
            return .none
        }()
        
        let bufferSize = bufferSize

        return AsyncStream { continuation in
            let task = Task {
                do {
                    let startDate = Date()
                    //  /**
                    //   We can read a file of 386 MB (or 1_000_000 lines) in 109 ms
                    //   But when we read it in chunks we take 3 seconds ...
                    //   */
                    //  let data = (try? Data(contentsOf: self)) ?? Data()
                    //  Log4swift[Self.self].info("[\(fileName)]  found: '\(data.count.decimalFormatted) lines' in: '\(startDate.elapsedTime)'")
                    //  Log4swift[Self.self].dash("[\(fileName)]  found: '\(data.count.decimalFormatted) lines' in: '\(startDate.elapsedTime)'")

                    let fileHandle = try FileHandle(forReadingFrom: self)
                    defer {
                        fileHandle.closeFile() // Ensure file is closed after reading
                    }
                    
                    var buffer = ArraySlice<UInt8>()
                    var atEof = false
                    var rowCount = 0

                    buffer.reserveCapacity(bufferSize * 2)
                    // Read data chunks from file until a line delimiter is found:
                    fileHandle.seek(toFileOffset: 0)
                    var fileSize = self.logicalSize
                    
                    Log4swift[Self.self].info("fileURL: '\(self.path)' with: '\(fileSize.decimalFormatted) bytes'")
                    while !atEof {
                        var lines = [ArraySlice<UInt8>]()
                        
                        lines.reserveCapacity(2048)
                        buffer = buffer.components(separatedBy: delimiter) { lineData in
                            rowCount += 1
                            fileSize -= Int64(lineData.count)
                            if rowCount % 500_000 == 0 {
                                let left = fileHandle.offsetInFile
                                Log4swift[Self.self].info("[\(fileName)] parsed: '\(rowCount.decimalFormatted) lines' consumed: '\(left.decimalFormatted)' remining: '\(fileSize.decimalFormatted) bytes'")
                            }
                            
                            lines.append(lineData)
                            if let fileHandle1 {
                                // deda debug
                                // write it back as data
                                fileHandle1.write(Data(lineData))
                                fileHandle1.write(Data([delimiter]))
                            }
                        }
                        
                        let tmpData = fileHandle.readData(ofLength: bufferSize)
                        if tmpData.count > 0 {
                            // we hve to copy a few bytes here ArraySlice 
                            buffer = ArraySlice<UInt8>(Data(buffer)) + ArraySlice<UInt8>(tmpData)
                        } else {
                            // EOF or read error.
                            atEof = true
                            
                            // Buffer contains last line in file (not terminated by delimiter).
                            if !buffer.isEmpty {
                                rowCount += 1
                                Log4swift[Self.self].info("[\(fileName)] found: '\(buffer.count.decimalFormatted) bytes' remining: '0 bytes'")
                                
                                lines.append(buffer)
                                if let fileHandle1 {
                                    // deda debug
                                    // write it back as data
                                    fileHandle1.write(Data(buffer))
                                    fileHandle1.write(Data([delimiter]))
                                }
                                buffer.removeAll()
                            }
                        }
                        
                        // push upstream
                        // Log4swift[Self.self].info("read: '\(lines.count.decimalFormatted) lines'")
                        continuation.yield(lines)
                    }
                    
                    Log4swift[Self.self].info("[\(fileName)]  found: '\(rowCount.decimalFormatted) lines' in: '\(startDate.elapsedTime)'")
                    Log4swift[Self.self].dash("[\(fileName)]  found: '\(rowCount.decimalFormatted) lines' in: '\(startDate.elapsedTime)'")
                    try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 1000)
                } catch {
                    Log4swift[Self.self].error("fileURL: '\(self.path)'")
                    Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                Log4swift[Self.self].info("[\(fileName)] terminated ...")
                task.cancel()
            }
        }
    }
}
