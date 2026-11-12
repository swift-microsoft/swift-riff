// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-riff",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [.library(name: "RIFF", targets: ["RIFF"])],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-binary.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RIFF",
            dependencies: [
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .testTarget(
            name: "RIFF Tests",
            dependencies: [
                .target(name: "RIFF"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
