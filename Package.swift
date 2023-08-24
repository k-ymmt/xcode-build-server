// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcode-build-server",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "xcode-build-server", targets: ["XcodeBuildServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "XcodeBuildServer",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
    ]
)
