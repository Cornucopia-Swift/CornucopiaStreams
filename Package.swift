// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3),
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
