// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "onward",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "OnwardCore", targets: ["OnwardCore"]),
        .library(name: "OnwardGenerators", targets: ["OnwardGenerators"]),
        .library(name: "Onward", targets: ["Onward"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "OnwardCore"),
        .testTarget(name: "OnwardTests", dependencies: ["OnwardCore"]),

        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "OnwardGeneratorsMacros",
            dependencies: [
               .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
               .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
           ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "OnwardGenerators", dependencies: ["OnwardCore", "OnwardGeneratorsMacros"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "OnwardGeneratorsTests",
            dependencies: [
                "OnwardGeneratorsMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),

        .target(
            name: "Onward",
            dependencies: ["OnwardCore", "OnwardGenerators"]
        ),
    ]
)
