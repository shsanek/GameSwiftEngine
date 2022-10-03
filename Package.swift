// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GameSwiftEngine",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "GameSwiftEngine",
            targets: ["GameSwiftEngine"]
        ),
        .library(
            name: "SpaceEditor",
            targets: ["SpaceEditor"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "GameSwiftEngine",
            dependencies: []
        ),
        .target(
            name: "SpaceEditor",
            dependencies: [.target(name: "GameSwiftEngine")]
        )
    ]
)
