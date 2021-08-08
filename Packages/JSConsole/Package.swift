// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSConsole",
    products: [
        .library(
            name: "JSConsole",
            targets: ["JSConsole"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JSConsole",
            dependencies: []),
        .testTarget(
            name: "JSConsoleTests",
            dependencies: ["JSConsole"]),
    ]
)
