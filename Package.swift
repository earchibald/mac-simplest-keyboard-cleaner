// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "keyboard-cleaner",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "keyboard-cleaner")
    ]
)
