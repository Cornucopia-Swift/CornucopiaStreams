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
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", .upToNextMajor(from: "0.4.0")),
    ],
    targets: [
        .target(name: "CSocketHelper"),
        .target(name: "CornucopiaStreams",
                dependencies: [
                    "CSocketHelper",
                    "CornucopiaCore",
                ]
        ),
        .testTarget(name: "CornucopiaStreamsTests", dependencies: ["CornucopiaStreams"]),
    ]
)
