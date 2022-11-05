// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CornucopiaStreams",
    platforms: [
        .macOS("12"),
        .iOS("15"),
        .tvOS("15"),
        .watchOS("8"),
        // Linux
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "CornucopiaStreams", targets: ["CornucopiaStreams"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", branch: "master"),
        // for the executable
        .package(url: "https://github.com/andybest/linenoise-swift", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
