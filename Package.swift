// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS("12"),
        .iOS("15"),
        .tvOS("15"),
        .watchOS("8"),
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
        .target(name: "CornucopiaStreams",
                dependencies: ["CSocketHelper"]
        ),
        .testTarget(name: "CornucopiaStreamsTests", dependencies: ["CornucopiaStreams"]),
    ]
)
