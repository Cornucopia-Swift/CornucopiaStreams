// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
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
