//
//  SystemProfiler.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/17/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa
import Foundation
import Log4swift

extension URL {
    public var isSSD: Bool {
        let volumeURL = self.volumeURL

        if let storageData = SystemProfiler.storageDataItems.first(where: { $0.mountPoint == volumeURL.path }) {
            Log4swift[Self.self].debug("storageData: '\(storageData)'")
            return storageData.physicalDrive.isSSD
        }

        let info = IOService.diskInfo(url: volumeURL)
        if let deviceModel = info["DADeviceModel"] as? String {
            if let storageData = SystemProfiler.storageDataItems.first(where: { $0.physicalDrive.deviceName == deviceModel }) {
                Log4swift[Self.self].debug("storageData: '\(storageData)'")
                return storageData.physicalDrive.isSSD
            }
        }

        var infoThinned = info

        infoThinned["DABusPath"] = .none
        infoThinned["DADevicePath"] = .none
        infoThinned["DAMediaIcon"] = .none
        infoThinned["DAMediaPath"] = .none
        infoThinned["DADiskRoles"] = .none
        infoThinned["DAVolumePath"] = .none

        Log4swift[Self.self].error("filePath: '\(self.path)' info: '\(infoThinned)'")
        return false
    }
}

public struct SystemProfiler: Sendable {
    nonisolated(unsafe)
    internal static var worker: Worker = .init()

    final class Worker: NSObject {
        private static let profilerURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")

        private let lock = NSRecursiveLock()
        nonisolated(unsafe)
        private var itemsNeedsRefetch = true
        nonisolated(unsafe)
        private var items: [SystemProfiler.StorageData] = []

        @objc private func didMountNotification(_ notification: NSNotification) {
            Self.lock.withLock {
                // Log4swift[Self.self].info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
                itemsNeedsRefetch = true
            }
        }

        @objc private func didUnmountNotification(_ notification: NSNotification) {
            Self.lock.withLock {
                // Log4swift[Self.self].info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
                itemsNeedsRefetch = true
            }
        }

        private static let lock = NSRecursiveLock()

        override init() {
            super.init()
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didMountNotification(_:)), name: NSWorkspace.didMountNotification, object: nil)
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didUnmountNotification(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        }

        internal func fetchItems() -> [SystemProfiler.StorageData] {
            Self.lock.withLock {
                guard itemsNeedsRefetch
                else { return items }

                let json = Process.stdString(taskURL: Self.profilerURL, arguments: ["-json", "SPStorageDataType"], timeOut: 10.0)
                do {
                    struct SPStorageDataType: Codable {
                        let SPStorageDataType: [StorageData]
                    }

                    Log4swift[Self.self].info("fetched: '\(json.count) bytes'")
                    let decoder = JSONDecoder()
                    let data = json.data(using: .utf8) ?? Data()
                    let rv = try decoder.decode(SPStorageDataType.self, from: data)
                    self.itemsNeedsRefetch = false
                    self.items = rv.SPStorageDataType
                    Log4swift[Self.self].info("items.count: '\(self.items.count)'")
                    Log4swift[Self.self].info("json: '\(json)'")

                    // test
                    //  let volumeIDs = rv.flatMap(\.items).map(\.volumeUUID)
                    //
                    //  volumeIDs.forEach { (volumeID) in
                    //      if let item = rv.volumeInfo(volumeID) {
                    //          Log4swift[Self.self].error("item: '\(item)'")
                    //      }
                    //  }
                } catch let error {
                    self.itemsNeedsRefetch = false
                    self.items = [StorageData]()
                    Log4swift[Self.self].error("error: '\(error)'")
                    Log4swift[Self.self].error("json: '\(json)'")
                }

                return self.items
            }
        }
    }

    public static var storageDataItems: [SystemProfiler.StorageData] {
        Self.worker.fetchItems()
    }
}

extension SystemProfiler {
    // convert xml to json
    // https://wtools.io/convert-plist-to-json
    // than convert json to schema
    // https://app.quicktype.io

    // MARK: - StorageData
    /**
     {
       "_name" : "Macintosh HD",
       "bsd_name" : "disk3s1s1",
       "file_system" : "APFS",
       "free_space_in_bytes" : 91987337216,
       "ignore_ownership" : "no",
       "mount_point" : "/",
       "physical_drive" : {
         "device_name" : "APPLE SSD AP1024Z",
         "is_internal_disk" : "yes",
         "media_name" : "AppleAPFSMedia",
         "medium_type" : "ssd",
         "partition_map_type" : "unknown_partition_map_type",
         "protocol" : "Apple Fabric",
         "smart_status" : "Verified"
       },
       "size_in_bytes" : 994662584320,
       "volume_uuid" : "E6896D98-5E68-45D7-8A56-CC13475566FC",
       "writable" : "no"
     }
     */
    public struct StorageData: Codable {
        public var bsdName: String
        public var fileSystem: String
        public var freeSpaceInBytes: Int
        public var mountPoint: String
        public var name: String
        public var physicalDrive: PhysicalDrive
        public var sizeInBytes: Int
        public var volumeUUID: String

        enum CodingKeys: String, CodingKey {
            case bsdName = "bsd_name"
            case fileSystem = "file_system"
            case freeSpaceInBytes = "free_space_in_bytes"
            case mountPoint = "mount_point"
            case name = "_name"
            case physicalDrive = "physical_drive"
            case sizeInBytes = "size_in_bytes"
            case volumeUUID = "volume_uuid"
        }
    }

    // MARK: - PhysicalDrive
    /**
     "physical_drive" : {
       "device_name" : "APPLE SSD AP1024Z",
       "is_internal_disk" : "yes",
       "media_name" : "AppleAPFSMedia",
       "medium_type" : "ssd",
       "partition_map_type" : "unknown_partition_map_type",
       "protocol" : "Apple Fabric",
       "smart_status" : "Verified"
     },
     */
    public struct PhysicalDrive: Codable {
        public var deviceName: String
        public var isInternalDisk: String
        public var mediaName: String
        public var mediumType: String
        public var partitionMapType: String
        public var physicalDriveProtocol: String
        public var smartStatus: String

        enum CodingKeys: String, CodingKey {
            case deviceName = "device_name"
            case isInternalDisk = "is_internal_disk"
            case mediaName = "media_name"
            case mediumType = "medium_type"
            case partitionMapType = "partition_map_type"
            case physicalDriveProtocol = "protocol"
            case smartStatus = "smart_status"
        }

        public var isSSD: Bool {
            mediumType.lowercased() == "ssd"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName) ?? ""
            self.isInternalDisk = try container.decodeIfPresent(String.self, forKey: .isInternalDisk) ?? ""
            self.mediaName = try container.decodeIfPresent(String.self, forKey: .mediaName) ?? ""
            self.mediumType = try container.decodeIfPresent(String.self, forKey: .mediumType) ?? ""
            self.partitionMapType = try container.decodeIfPresent(String.self, forKey: .partitionMapType) ?? ""
            self.physicalDriveProtocol = try container.decodeIfPresent(String.self, forKey: .physicalDriveProtocol) ?? ""
            self.smartStatus = try container.decodeIfPresent(String.self, forKey: .smartStatus) ?? ""
        }
    }
}

#endif
