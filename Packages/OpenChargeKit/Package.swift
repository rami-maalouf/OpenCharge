// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpenChargeKit",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "OpenChargeCore", targets: ["OpenChargeCore"]),
        .library(name: "OpenChargeSystem", targets: ["OpenChargeSystem"]),
        .library(name: "OpenChargeFeatures", targets: ["OpenChargeFeatures"])
    ],
    targets: [
        .target(name: "OpenChargeCore"),
        .target(
            name: "OpenChargeSystem",
            dependencies: ["OpenChargeCore"]
        ),
        .target(
            name: "OpenChargeFeatures",
            dependencies: ["OpenChargeCore"]
        ),
        .testTarget(
            name: "OpenChargeCoreTests",
            dependencies: ["OpenChargeCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
