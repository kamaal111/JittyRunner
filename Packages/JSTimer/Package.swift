// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSTimer",
    products: [
        .library(
            name: "JSTimer",
            targets: ["JSTimer"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JSTimer",
            dependencies: []),
        .testTarget(
            name: "JSTimerTests",
            dependencies: ["JSTimer"]),
    ]
)
