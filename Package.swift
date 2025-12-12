// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gtfs-importer",
    platforms: [
        .macOS(SupportedPlatform.MacOSVersion.v11),
        .iOS(SupportedPlatform.IOSVersion.v12)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", from: "6.29.1"),
        .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.4.3")),
        // Use local GTFSModel for development
        .package(path: "../GTFSModel")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "gtfs-importer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift"),
                "GRDB",
                "GTFSModel"
            ]),
        .testTarget(
            name: "gtfs-importerTests",
            dependencies: ["gtfs-importer", "GTFSModel"]),
    ]
)
