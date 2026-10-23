// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DevDeckKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "DevDeckKit", targets: ["DevDeckKit"]),
    ],
    targets: [
        .target(name: "DevDeckKit"),
        .testTarget(name: "DevDeckKitTests", dependencies: ["DevDeckKit"]),
    ]
)
