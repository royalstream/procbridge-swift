// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Procbridge",
    platforms: [ .macOS(.v10_14) ],
    products: [
        .library(
            name: "Procbridge",
            targets: ["Procbridge"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Procbridge",
            dependencies: []),
        .testTarget(
            name: "ProcbridgeTests",
            dependencies: ["Procbridge"]),
    ]
)
