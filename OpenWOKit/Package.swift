// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenWOKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "OpenWOKit", targets: ["OpenWOKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "OpenWOKit",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            exclude: {
                #if os(Linux)
                return ["Views", "Utilities/PlatformColors.swift", "ViewModels"]
                #else
                return []
                #endif
            }(),
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OpenWOKitTests",
            dependencies: ["OpenWOKit"],
            exclude: {
                #if os(Linux)
                return ["ExerciseViewModelTests.swift", "HomeViewModelTests.swift", "HealthKitIntegrationTests.swift"]
                #else
                return []
                #endif
            }()
        ),
    ]
)
