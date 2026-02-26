// swift-tools-version: 5.10
//
// Prove SDK (FrameOnboarding): One-time registry setup may be required for resolution:
//   swift package-registry set --global "https://prove.jfrog.io/artifactory/api/swift/libs-public-swift"
//   swift package-registry login "https://prove.jfrog.io/artifactory/api/swift/libs-public-swift"  # Press Enter for public registry

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
        .package(url: "https://github.com/SiftScience/sift-ios.git", .revision("bcbbd164f4e83076688eda28fdbc93c09e104e1a")),
        .package(id: "swift.proveauth", from: "6.10.2")
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
                    .target(name: "Frame"),
                    .product(name: "ProveAuth", package: "swift.proveauth", condition: .when(platforms: [.iOS]))
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
