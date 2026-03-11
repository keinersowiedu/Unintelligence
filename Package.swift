// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppleIntelligenceRemover",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AppleIntelligenceRemover",
            path: "Sources"
        )
    ]
)
