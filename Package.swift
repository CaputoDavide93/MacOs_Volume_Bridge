// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macOSAudioBridge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "macOSAudioBridge",
            targets: ["macOSAudioBridge"]
        )
    ],
    targets: [
        .executableTarget(
            name: "macOSAudioBridge",
            dependencies: [],
            path: "Sources",
            resources: []
        )
    ]
)
