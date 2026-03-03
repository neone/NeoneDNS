// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NeoneDNS",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "NeoneDNS",
            targets: ["NeoneDNS"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NeoneDNS",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "NeoneDNSTests",
            dependencies: ["NeoneDNS"],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableExperimentalFeature("StrictConcurrency"),
] }
