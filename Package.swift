// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WarcKit",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "WarcKit",
            targets: ["WarcKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mihai8804858/swift-gzip.git", branch: "main"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "WarcKit",
            dependencies: [
                .product(name: "SwiftGzip", package: "swift-gzip"),
                "SwiftSoup",
            ]
        ),
        .testTarget(
            name: "WarcKitTests",
            dependencies: ["WarcKit"],
            resources: [
                .copy("TestFixtures/autoindex.cdxj"),
                .copy("TestFixtures/data.warc.gz"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
