// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NeeCharacter",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NeeCharacter", targets: ["NeeCharacter"]),
    ],
    targets: [
        .target(name: "NeeCharacter"),
    ]
)
