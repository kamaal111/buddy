// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Chat", targets: ["Chat"]),
        .library(name: "Authentication", targets: ["Authentication"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../BuddyClient")
    ],
    targets: [
        .target(name: "Chat", dependencies: ["DesignSystem"]),
        .target(name: "Authentication", dependencies: ["BuddyClient", "DesignSystem"]),
    ]
)
