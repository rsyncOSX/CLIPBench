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
        .package(path: "../PhotoAIKit")
    ],
    targets: [
        .target(
            name: "CLIPBenchCore",
            dependencies: [
                .product(name: "PhotoAIContracts", package: "PhotoAIKit"),
                .product(name: "PhotoAIWorkflows", package: "PhotoAIKit"),
                .product(name: "CoreAICLIPBackend", package: "PhotoAIKit"),
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
