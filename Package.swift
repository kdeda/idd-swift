// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IDDSwift",
            targets: ["IDDSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-log4-swift-v2.git", from: "2.0.2"),
        .package(url: "https://github.com/kdeda/idd-zstd-swift.git", from: "1.3.2"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.2.4")
    ],
    targets: [
        .target(
            name: "IDDSwift",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift-v2"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "IDDSwiftTests",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift-v2"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        )
    ]
)
