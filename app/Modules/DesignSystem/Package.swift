// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignSystem",
    defaultLocalization: "en",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    dependencies: [
        .package(path: "../swift-validator")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "SwiftValidator", package: "swift-validator")
            ],
            resources: [.process("Resources/Assets.xcassets")]
        ),
    ]
)
