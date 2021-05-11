// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS("10.15.4"),
        .iOS("13.4"),
        .tvOS("13.4"),
        .watchOS("6"),
    ],
    products: [
        .library(
            name: "CornucopiaStreams",
            targets: ["CornucopiaStreams"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "CSocketHelper"),
        .target(name: "CornucopiaStreams", dependencies: ["CSocketHelper"]),
        .testTarget(name: "CornucopiaStreamsTests", dependencies: ["CornucopiaStreams"]),
    ]
)
