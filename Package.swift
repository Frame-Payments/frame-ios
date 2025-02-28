// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Frame-iOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Frame-iOS",
            targets: ["Frame-iOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/evervault/evervault-ios.git", from: "1.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Frame-iOS",
            dependencies: [
                .product(name: "EvervaultInputs", package: "evervault-ios"),
                .product(name: "EvervaultEnclaves", package: "evervault-ios")
            ],
            resources: [.process("Resources")],
            swiftSettings: [
                .define("EXCLUDE_MACOS", .when(platforms: [.macOS])) // 👈 Prevents macOS builds
            ]
        ),
        .testTarget(
            name: "Frame-iOSTests",
            dependencies: ["Frame-iOS"]
        ),
    ]
)
