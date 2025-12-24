// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gtfs-importer",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.2"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.9.0"),
        .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.5.2")),
        .package(url: "https://github.com/jogi/GTFSModel", branch: "upgrade-swift6-grdb7")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "gtfs-importer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift"),
                .product(name: "GRDB", package: "GRDB.swift"),
                "GTFSModel"
            ]),
        .testTarget(
            name: "gtfs-importerTests",
            dependencies: ["gtfs-importer", "GTFSModel"],
            resources: [.copy("testData")]),
    ]
)
