//
//  SystemProfiler.swift
//  IDDSwift
//
//  Created by Klajd Deda on 3/17/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation
import Log4swift

extension URL {
    nonisolated(unsafe)
    private static var fetchedVolumes = [String: Bool]()
    private static let lock = NSRecursiveLock()

    public var isSSD: Bool {
        Self.lock.withLock {
            let volumeUUID = self.volumeUUID
            if let existing = Self.fetchedVolumes[volumeUUID] {
                return existing
            }

            //    // not giving us disk info
            //    let diskInfo = IOService.diskInfo(url: rootNode.fileURL.volumeURL)
            //    Log4swift[Self.self].info("diskInfo: '\(diskInfo)'")

            let newValue = {
                let storage = SystemProfiler.shared.storageData
                // Log4swift[Self.self].info("storage: '\(storage)'")
                let items = storage.flatMap(\.items)

                items.forEach {
                    Log4swift[Self.self].debug("item: '\($0)'")
                }
                if let ourItem = items.filter({ $0.volumeUUID == volumeUUID }).first {
                    Log4swift[Self.self].info("storage: '\(ourItem)'")

                    if let physicalDrive = ourItem.physicalDrive {
                        Log4swift[Self.self].info("storage: '\(physicalDrive)'")
                    }
                    return ourItem.isSSD
                }
                return false
            }()

            Self.fetchedVolumes[volumeUUID] = newValue
            return newValue
        }
    }
}

public struct SystemProfiler: Sendable {
    public static let shared = SystemProfiler()
    public static let profilerURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")

    public var storageData: [SystemProfiler.StorageData] {
        let xml = Process.stdString(taskURL: SystemProfiler.profilerURL, arguments: ["-xml", "SPStorageDataType"], timeOut: 5.0)

        do {
            let decoder = PropertyListDecoder()
            let data = xml.data(using: .utf8) ?? Data()
            let rv = try decoder.decode([StorageData].self, from: data)

            // test
            //  let volumeIDs = rv.flatMap(\.items).map(\.volumeUUID)
            //
            //  volumeIDs.forEach { (volumeID) in
            //      if let item = rv.volumeInfo(volumeID) {
            //          Log4swift[Self.self].error("item: '\(item)'")
            //      }
            //  }
            return rv
        } catch let error {
            Log4swift[Self.self].error("xml: '\(xml)'")
            Log4swift[Self.self].error("error: '\(error)'")
        }
        return [StorageData]()
    }
}

extension SystemProfiler.Item {
    public var isSSD: Bool {
        (physicalDrive.map { $0.mediumType == "ssd" }) ?? false
    }
}

extension Array where Element == SystemProfiler.StorageData {
    public func volumeInfo(_ volumeID: String) -> SystemProfiler.Item? {
        let items = self.flatMap(\.items)
        return items.first { (storageData) -> Bool in
            storageData.volumeUUID == volumeID
        }
    }
}

extension SystemProfiler {
    // convert xml to json
    // https://wtools.io/convert-plist-to-json
    // than convert json to schema
    // https://app.quicktype.io
    
    // MARK: - SystemProfilerElement
    public struct StorageData: Codable {
        public var spCommandLineArguments: [String]
        public var spCompletionInterval, spResponseTime: Double
        public var dataType: String
        public var items: [Item]
        public var parentDataType: String
        public var properties: Properties
        public var timeStamp: Date
        public var versionInfo: VersionInfo

        enum CodingKeys: String, CodingKey {
            case spCommandLineArguments = "_SPCommandLineArguments"
            case spCompletionInterval = "_SPCompletionInterval"
            case spResponseTime = "_SPResponseTime"
            case dataType = "_dataType"
            case items = "_items"
            case parentDataType = "_parentDataType"
            case properties = "_properties"
            case timeStamp = "_timeStamp"
            case versionInfo = "_versionInfo"
        }
    }
    
    // MARK: - Item
    public struct Item: Codable {
        public var name, bsdName, fileSystem: String
        public var freeSpaceInBytes: Int
        public var ignoreOwnership, mountPoint: String
        public var physicalDrive: PhysicalDrive?
        public var sizeInBytes: Int
        public var volumeUUID, writable: String

        enum CodingKeys: String, CodingKey {
            case name = "_name"
            case bsdName = "bsd_name"
            case fileSystem = "file_system"
            case freeSpaceInBytes = "free_space_in_bytes"
            case ignoreOwnership = "ignore_ownership"
            case mountPoint = "mount_point"
            case physicalDrive = "physical_drive"
            case sizeInBytes = "size_in_bytes"
            case volumeUUID = "volume_uuid"
            case writable
        }
    }
    
    // MARK: - PhysicalDrive
    public struct PhysicalDrive: Codable {
        public var deviceName, isInternalDisk, mediaName: String
        public var partitionMapType, physicalDriveProtocol: String
        public var mediumType: String?
        public var smartStatus: String?

        enum CodingKeys: String, CodingKey {
            case deviceName = "device_name"
            case isInternalDisk = "is_internal_disk"
            case mediaName = "media_name"
            case mediumType = "medium_type"
            case partitionMapType = "partition_map_type"
            case physicalDriveProtocol = "protocol"
            case smartStatus = "smart_status"
        }
    }
    
    // MARK: - Properties
    public struct Properties: Codable {
        public var name: Name
        public var bsdName: BSDName
        public var comAppleCorestorageLV: COMAppleCorestorageLV
        public var comAppleCorestorageLVBytesConverted: COMAppleCorestorage
        public var comAppleCorestorageLVConversionState, comAppleCorestorageLVEncrypted, comAppleCorestorageLVEncryptionType, comAppleCorestorageLVLocked: COMAppleCorestorageLV
        public var comAppleCorestorageLVRevertible, comAppleCorestorageLVUUID, comAppleCorestorageLvg: COMAppleCorestorageLV
        public var comAppleCorestorageLvgFreeSpace: COMAppleCorestorage
        public var comAppleCorestorageLvgName: COMAppleCorestorageLV
        public var comAppleCorestorageLvgSize: COMAppleCorestorage
        public var comAppleCorestorageLvgUUID, comAppleCorestoragePV: COMAppleCorestorageLV
        public var comAppleCorestoragePVSize: COMAppleCorestorage
        public var comAppleCorestoragePVStatus, comAppleCorestoragePVUUID, deviceName: COMAppleCorestorageLV
        public var fileSystem: BSDName
        public var freeSpaceInBytes: FreeSpaceInBytes
        public var ignoreOwnership, isInternalDisk, mediaName, mediumType: COMAppleCorestorageLV
        public var mountPoint: BSDName
        public var opticalMediaType, partitionMapType, propertiesProtocol: COMAppleCorestorageLV
        public var sizeInBytes: SizeInBytes
        public var smartStatus, volumeUUID: COMAppleCorestorageLV
        public var volumes: Volumes
        public var writable: COMAppleCorestorageLV

        enum CodingKeys: String, CodingKey {
            case name = "_name"
            case bsdName = "bsd_name"
            case comAppleCorestorageLV = "com.apple.corestorage.lv"
            case comAppleCorestorageLVBytesConverted = "com.apple.corestorage.lv.bytesConverted"
            case comAppleCorestorageLVConversionState = "com.apple.corestorage.lv.conversionState"
            case comAppleCorestorageLVEncrypted = "com.apple.corestorage.lv.encrypted"
            case comAppleCorestorageLVEncryptionType = "com.apple.corestorage.lv.encryptionType"
            case comAppleCorestorageLVLocked = "com.apple.corestorage.lv.locked"
            case comAppleCorestorageLVRevertible = "com.apple.corestorage.lv.revertible"
            case comAppleCorestorageLVUUID = "com.apple.corestorage.lv.uuid"
            case comAppleCorestorageLvg = "com.apple.corestorage.lvg"
            case comAppleCorestorageLvgFreeSpace = "com.apple.corestorage.lvg.freeSpace"
            case comAppleCorestorageLvgName = "com.apple.corestorage.lvg.name"
            case comAppleCorestorageLvgSize = "com.apple.corestorage.lvg.size"
            case comAppleCorestorageLvgUUID = "com.apple.corestorage.lvg.uuid"
            case comAppleCorestoragePV = "com.apple.corestorage.pv"
            case comAppleCorestoragePVSize = "com.apple.corestorage.pv.size"
            case comAppleCorestoragePVStatus = "com.apple.corestorage.pv.status"
            case comAppleCorestoragePVUUID = "com.apple.corestorage.pv.uuid"
            case deviceName = "device_name"
            case fileSystem = "file_system"
            case freeSpaceInBytes = "free_space_in_bytes"
            case ignoreOwnership = "ignore_ownership"
            case isInternalDisk = "is_internal_disk"
            case mediaName = "media_name"
            case mediumType = "medium_type"
            case mountPoint = "mount_point"
            case opticalMediaType = "optical_media_type"
            case partitionMapType = "partition_map_type"
            case propertiesProtocol = "protocol"
            case sizeInBytes = "size_in_bytes"
            case smartStatus = "smart_status"
            case volumeUUID = "volume_uuid"
            case volumes, writable
        }
    }
    
    // MARK: - BSDName
    public struct BSDName: Codable {
        public var isColumn: Bool
        public var order: String

        enum CodingKeys: String, CodingKey {
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - COMAppleCorestorageLV
    public struct COMAppleCorestorageLV: Codable {
        public var order: String

        enum CodingKeys: String, CodingKey {
            case order = "_order"
        }
    }
    
    // MARK: - COMAppleCorestorage
    public struct COMAppleCorestorage: Codable {
        public var isByteSize: Bool
        public var order: String

        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case order = "_order"
        }
    }
    
    // MARK: - FreeSpaceInBytes
    public struct FreeSpaceInBytes: Codable {
        public var isByteSize, isColumn: Bool
        public var order: String

        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - Name
    public struct Name: Codable {
        public var isColumn, order: String
        public var suppressLocalization: Bool

        enum CodingKeys: String, CodingKey {
            case isColumn = "_isColumn"
            case order = "_order"
            case suppressLocalization = "_suppressLocalization"
        }
    }
    
    // MARK: - SizeInBytes
    public struct SizeInBytes: Codable {
        public var isByteSize: String
        public var isColumn: Bool
        public var order: String

        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - Volumes
    public struct Volumes: Codable {
        public var detailLevel: String

        enum CodingKeys: String, CodingKey {
            case detailLevel = "_detailLevel"
        }
    }
    
    // MARK: - VersionInfo
    public struct VersionInfo: Codable {
        public var comAppleSystemProfilerSPStorageReporter: String

        enum CodingKeys: String, CodingKey {
            case comAppleSystemProfilerSPStorageReporter = "com.apple.SystemProfiler.SPStorageReporter"
        }
    }
}

#endif
