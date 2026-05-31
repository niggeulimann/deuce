// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Deuce",
    platforms: [.watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "Deuce", targets: ["Deuce"]),
    ],
    targets: [
        .target(
            name: "Deuce",
            path: "Sources/Deuce"
        ),
        .testTarget(
            name: "DeuceTests",
            dependencies: ["Deuce"],
            path: "Tests/DeuceTests"
        ),
    ]
)
