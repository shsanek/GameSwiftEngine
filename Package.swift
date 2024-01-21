// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GameSwiftEngine",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(
            name: "GameSwiftEngine",
            targets: ["GameSwiftEngine"]
        ),
        .executable(name: "DemoApp", targets: ["DemoApp"])
    ],
    dependencies: [
        // .package(path: "../ObjectEditor")
        .package(url: "https://github.com/shsanek/ObjectEditor.git", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "DemoApp",
            dependencies: [
                "GameSwiftDemo"
            ]
        ),
        .executableTarget(
            name: "EditorDemo",
            dependencies: [
                "Editor",
                "GameSwiftDemo"
            ]
        ),
        .target(
            name: "GameSwiftDemo",
            dependencies: [
                "GameSwiftEngine",
                .product(name: "ObjectEditor", package: "ObjectEditor")
            ],
            resources: [
                .copy("Resources"),
            ]
        ),
        .target(
            name: "Editor",
            dependencies: [
                .product(name: "ObjectEditor", package: "ObjectEditor"),
                "GameSwiftEngine"
            ]
        ),
        .target(
            name: "GameSwiftEngine",
            dependencies: [
                .product(name: "ObjectEditor", package: "ObjectEditor"),
                "WADFormat"
            ]
        ),
        .target(
            name: "WADFormat",
            publicHeadersPath: "PublicHeader",
            linkerSettings: [ .linkedLibrary("c++abi") ]
        )
    ]
)
