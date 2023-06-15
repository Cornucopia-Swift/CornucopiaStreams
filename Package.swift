// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS(.v12),
        .macCatalyst(.v15),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        // Linux
    ],
    products: [
        .library(name: "CornucopiaStreams", targets: ["CornucopiaStreams"]),
    ],
    dependencies: [
        // for the library
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", branch: "master"),
        // for the executable
        .package(url: "https://github.com/andybest/linenoise-swift", branch: "master"),
    ],
    targets: [
        .target(name: "CSocketHelper"),
        .target(
            name: "CornucopiaStreams",
            dependencies: [
                "CSocketHelper",
                "CornucopiaCore",
            ]
        ),
        .executableTarget(
            name: "streamer",
            dependencies: [
                "CornucopiaStreams",
                .product(name: "LineNoise", package: "linenoise-swift"),
            ]
        ),
        .testTarget(
            name: "CornucopiaStreamsTests",
            dependencies: ["CornucopiaStreams"]),
    ]
)
