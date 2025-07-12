// swift-tools-version:5.9
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
        ),
        .testTarget(
            name: "ClipTyperTests",
            dependencies: ["ClipTyper"],
            path: "Tests",
            linkerSettings: [
                .linkedFramework("XCTest")
            ]
        )
    ]
)

// ClipTyper - Free and Open Source Software
// Licensed under GNU General Public License v3.0
// Copyright © 2025 Ralf Sturhan
// See LICENSE file for full license text 