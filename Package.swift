// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "llamacpp-wrapper",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v4),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "llamacpp-wrapper",
            type: .dynamic,
            targets: ["llamacpp-wrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ggerganov/llama.cpp.git", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "llamacpp-wrapper",
            dependencies: [
                .product(
                    name: "llama",
                    package: "llama.cpp")
            ]),
//        .testTarget(
//            name: "llamacpp-wrapperTests",
//            dependencies: ["llamacpp-wrapper"]),
    ]
)
