// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ClipTyper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ClipTyper", targets: ["ClipTyper"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClipTyper",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 