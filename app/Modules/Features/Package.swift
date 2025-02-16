// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Chat", targets: ["Chat"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "Chat", dependencies: ["DesignSystem"]),
    ]
)
