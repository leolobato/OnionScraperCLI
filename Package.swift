// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OnionScraper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "onionscraper", targets: ["OnionScraper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/leolobato/ScreenScraperClient.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "OnionScraper",
            dependencies: [
                "ScreenScraperClient",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "OnionScraperTests",
            dependencies: ["OnionScraper"]),
    ]
)
