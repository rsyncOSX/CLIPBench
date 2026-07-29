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
        .package(path: "../PhotoAIKit"),
        .package(path: "../RawParserKit"),
    ],
    targets: [
        .target(
            name: "CLIPBenchCore",
            dependencies: [
                .product(name: "PhotoAIContracts", package: "PhotoAIKit"),
                .product(name: "PhotoAIWorkflows", package: "PhotoAIKit"),
                .product(name: "CoreAICLIPBackend", package: "PhotoAIKit"),
                .product(name: "RawParserKit", package: "RawParserKit"),
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
