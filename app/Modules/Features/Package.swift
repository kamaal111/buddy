// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Chat", targets: ["Chat"]),
    ],
    targets: [
        .target(name: "Chat"),
    ]
)
