// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PrefsHelper",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "PrefsHelper", targets: ["PrefsHelper"]),
    ],
    targets: [
        .target(name: "PrefsHelper", path: "Source"),
        .testTarget(name: "PrefsHelperTests", dependencies: ["PrefsHelper"], path: "Tests"),
    ]
)
