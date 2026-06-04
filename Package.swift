// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v18),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v10),
        // Linux
    ],
    products: [
        .library(name: "CornucopiaStreams", targets: ["CornucopiaStreams"]),
    ],
    dependencies: [
        // for the library
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", branch: "master"),
        .package(url: "https://github.com/mickeyl/FoundationBandAid", branch: "master"),
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
                .product(name: "FoundationBandAid", package: "FoundationBandAid", condition: .when(platforms: [.linux])),
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
    ],
    swiftLanguageModes: [.v5]
)
