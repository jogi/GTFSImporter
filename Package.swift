// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gtfs-importer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.5"),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", from: "4.13.0"),
        .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.4.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "gtfs-importer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift"),
                "GRDB"
            ]),
        .testTarget(
            name: "gtfs-importerTests",
            dependencies: ["gtfs-importer"]),
    ]
)
