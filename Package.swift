// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IDDSwift",
            targets: ["IDDSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", from: "1.2.3")
    ],
    targets: [
        .target(
            name: "IDDSwift",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        ),
        .testTarget(
            name: "IDDSwiftTests",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        )
    ]
)
