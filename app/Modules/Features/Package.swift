// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "Chat", targets: ["Chat"]),
        .library(name: "Authentication", targets: ["Authentication"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kamaalio/KamaalSwift", "2.3.1"..<"3.0.0"),
        .package(path: "../DesignSystem"),
        .package(path: "../BuddyClient")
    ],
    targets: [
        .target(name: "Chat", dependencies: [
            .product(name: "KamaalExtensions", package: "KamaalSwift"),
            .product(name: "KamaalUtils", package: "KamaalSwift"),
            "DesignSystem",
            "Authentication",
            "BuddyClient",
        ]),
        .target(name: "Authentication", dependencies: ["BuddyClient", "DesignSystem"]),
    ]
)
