// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EENApiToolkit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "EENApiToolkit", targets: ["EENApiToolkit"])
    ],
    targets: [
        .target(name: "EENApiToolkit"),
        .testTarget(
            name: "EENApiToolkitTests",
            dependencies: ["EENApiToolkit"]
        )
    ]
)
