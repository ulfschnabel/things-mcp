// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "things-mcp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // CLI executable (includes all code)
        .executableTarget(
            name: "things-mcp",
            path: "Sources/ThingsMCP"
        ),
        // Menu bar app executable
        .executableTarget(
            name: "ThingsMCPApp",
            path: "Sources/ThingsMCPApp"
        )
    ]
)
