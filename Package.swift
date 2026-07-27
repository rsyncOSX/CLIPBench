// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "CLIPBench",
    platforms: [
        .macOS("27.0")
    ],
    products: [
        .executable(name: "clipbench", targets: ["CLIPBench"]),
        .library(name: "CLIPBenchCore", targets: ["CLIPBenchCore"]),
    ],
    dependencies: [
        .package(path: "../PhotoAIKitTest")
    ],
    targets: [
        .target(
            name: "CLIPBenchCore",
            dependencies: [
                .product(name: "PhotoAIContracts", package: "PhotoAIKitTest"),
                .product(name: "PhotoAIWorkflows", package: "PhotoAIKitTest"),
                .product(name: "CoreAICLIPBackend", package: "PhotoAIKitTest"),
            ]
        ),
        .executableTarget(
            name: "CLIPBench",
            dependencies: ["CLIPBenchCore"]
        ),
        .testTarget(
            name: "CLIPBenchCoreTests",
            dependencies: ["CLIPBenchCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
