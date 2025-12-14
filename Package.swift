// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "IDDSwift",
            targets: ["IDDSwift"]
        )
    ],
    dependencies: [
        // .package(name: "idd-log4-swift", path: "../idd-log4-swift"),
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "2.2.11" ..< "3.0.0"),
        .package(url: "https://github.com/kdeda/idd-zstd-swift.git", "2.0.1" ..< "3.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "4.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.1.3")
    ],
    targets: [
        .target(
            name: "IDDSwift",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "IDDSwiftTests",
            dependencies: [
                "IDDSwift",
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        )
    ]
)
