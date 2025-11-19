// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SkipFrame",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SkipFrame",
            targets: ["SkipFrame"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0")
    ],
    targets: [
        .target(
            name: "SkipFrame",
            sources: ["ButtonsManager.swift", "DrawingView.swift", "SkipFrame.swift"]
        )
    ]
)
