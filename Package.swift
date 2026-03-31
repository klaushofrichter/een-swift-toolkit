// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EENSwiftToolkit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "EENSwiftToolkit", targets: ["EENSwiftToolkit"])
    ],
    targets: [
        .target(name: "EENSwiftToolkit"),
        .testTarget(
            name: "EENSwiftToolkitTests",
            dependencies: ["EENSwiftToolkit"]
        )
    ]
)
