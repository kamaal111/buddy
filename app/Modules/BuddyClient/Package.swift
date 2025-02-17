// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyClient",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "BuddyClient", targets: ["BuddyClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", "1.7.0"..<"2.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", "1.8.0"..<"2.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", "1.0.2"..<"2.0.0"),
    ],
    targets: [
        .target(
            name: "BuddyClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
    ]
)
