// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Frame-iOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Frame-iOS", targets: ["Frame"]),
        .library(
            name: "Frame-Onboarding", targets: ["FrameOnboarding"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/evervault/evervault-ios.git", from: "1.3.0"),
        .package(url: "https://github.com/SiftScience/sift-ios.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Frame",
            dependencies: [
                .product(name: "EvervaultCore", package: "evervault-ios", condition: .when(platforms: [.iOS])),
                .product(name: "EvervaultInputs", package: "evervault-ios", condition: .when(platforms: [.iOS])),
                .product(name: "sift-ios", package: "sift-ios", condition: .when(platforms: [.iOS]))
            ],
            resources: [.process("Resources")],
            swiftSettings: [
                .define("EXCLUDE_MACOS", .when(platforms: [.macOS]))
            ]
        ),
        .target(name: "FrameOnboarding",
                dependencies: [
                    .target(name: "Frame")
                ],
                swiftSettings: [
                    .define("EXCLUDE_MACOS", .when(platforms: [.macOS]))
                ]
        ),
        .testTarget(
            name: "Frame-iOSTests",
            dependencies: ["Frame"]
        ),
    ]
)
