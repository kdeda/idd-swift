//
//  URL+FileChange.swift
//  IDDSwift
//
//  Created by Klajd Deda on 6/3/23.
//  Copyright (C) 1997-2026 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation

public extension URL {
    /**
     Emit a stream of FileChange values as soon as we detect changes from the file system.
     The first value will be of type .started(Data) than subsequent values are .added(Data)
     
     This allows one to 'tail' a particular file. We can refine this func with arguments
     similar to how tail works.
     
     Changes to a file are typically done by some other process that is writing to that file.
     If the file is removed from the file system, this stream will terminate.
     */
    func fileChanges() -> AsyncStream<FileChange> {
        AsyncStream { continuation in
            let monitor = try? FileChangeListener(self, eventHandler: { event in
                continuation.yield(event)
                
                if event == .fileDeleted {
                    continuation.finish()
                }
            })
            
            continuation.onTermination = { _ in
                _ = monitor
            }
            monitor?.start()
        }
    }
}

public extension DispatchSourceFileSystemObject {
    var eventName: [String] {
        var s = [String]()
        if data.contains(.all)      { s.append("all") }
        if data.contains(.attrib)   { s.append("attrib") }
        if data.contains(.delete)   { s.append("delete") }
        if data.contains(.extend)   { s.append("extend") }
        if data.contains(.funlock)  { s.append("funlock") }
        if data.contains(.link)     { s.append("link") }
        if data.contains(.rename)   { s.append("rename") }
        if data.contains(.revoke)   { s.append("revoke") }
        if data.contains(.write)    { s.append("write") }
        return s
    }
}

/**
 Given a file url it will listen for .write events and notify
 when the children are added/removed to the url. This code will not recurse down to children
 */
fileprivate final class FileChangeListener: @unchecked Sendable {
    private(set) var url: URL
    private let eventType: DispatchSource.FileSystemEvent = [.extend, .delete]
    private(set) var eventHandler: (FileChange) -> Void
    
    private var fileHandle: FileHandle!
    private var source: DispatchSourceFileSystemObject!
    
    public init(
        _ url: URL,
        eventHandler: @escaping (FileChange) -> Void
    ) throws {
        Log4swift[Self.self].info("path: '\(url.path)'")

        self.url = url
        self.eventHandler = eventHandler
        self.fileHandle = try FileHandle(forReadingFrom: url)
    }
    
    deinit {
        Log4swift[Self.self].info("path: '\(url.path)'")
    }
    
    /// Open the url and listen for write events.
    /// A write event occurs when a subfolder or a file is added removed to the url we are monitoring
    /// If the url we are monitoring is removed we also receive a write event.
    public func start() -> Void {
        Log4swift[Self.self].info("path: '\(url.path)'")

        // start reading changes ...
        // and report initial state
        let newData = fileHandle.readDataToEndOfFile()
        fileHandle.seekToEndOfFile()
        Log4swift[Self.self].info("path: '\(url.path)' found: '\(newData.count) bytes'")
        eventHandler(.started(newData))
        
        self.source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: eventType,
            queue: DispatchQueue.global(qos: .background)
        )
        source.setEventHandler(qos: .background, flags: [.assignCurrentContext]) { [weak self] in
            guard let strongSelf = self
            else { return }
            
            let event = DispatchSource.FileSystemEvent(rawValue: strongSelf.source.data.rawValue)
            switch event {
            case .delete:
                // the file was deleted
                Log4swift[Self.self].info("path: '\(strongSelf.url.path)' just got deleted'")
                strongSelf.eventHandler(.fileDeleted)

            case .extend:
                // report changes as we detect them
                let newData = strongSelf.fileHandle.readDataToEndOfFile()
                strongSelf.eventHandler(.added(newData))
            default:
                Log4swift[Self.self].error("path: '\(strongSelf.url.path)' received unmanaged event: \(strongSelf.source.eventName)'")
            }
        }
        source.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            try? strongSelf.fileHandle.close()
        }
        source.resume()
    }
    
    func stop() {
        source.cancel()
    }

}

#endif
