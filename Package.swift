// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ProjectGreenlight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "GreenlightCore", targets: ["GreenlightCore"]),
        .executable(name: "GreenlightApp", targets: ["GreenlightApp"])
    ],
    targets: [
        .target(name: "GreenlightCore"),
        .executableTarget(
            name: "GreenlightApp",
            dependencies: ["GreenlightCore"]
        ),
        .testTarget(
            name: "GreenlightCoreTests",
            dependencies: ["GreenlightCore"]
        )
    ]
)
