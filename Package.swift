// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RegiBoxClient",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "RegiBoxClient",
            targets: ["RegiBoxClient"]
        ),
        .executable(
            name: "regybox",
            targets: ["RegiBoxDemo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "RegiBoxClient",
            dependencies: ["SwiftSoup"]
        ),
        .executableTarget(
            name: "RegiBoxDemo",
            dependencies: [
                "RegiBoxClient",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "RegiBoxClientTests",
            dependencies: ["RegiBoxClient"]
        ),
    ]
)
