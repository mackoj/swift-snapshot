// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-snapshot",
  platforms: [.macOS(.v13), .iOS(.v15)],
  products: [
    .library(
      name: "SwiftSnapshot",
      targets: ["SwiftSnapshot"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.2.0"),
  ],
  targets: [
    // Macro implementation (compiler plugin + public macro definitions)
    .macro(
      name: "SwiftSnapshotMacros",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
      path: "Sources/SwiftSnapshotMacros"
    ),

    // Core runtime library implementation
    .target(
      name: "SwiftSnapshotCore",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftFormat", package: "swift-format"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ],
      path: "Sources/SwiftSnapshotCore"
    ),

    // Unified import module (re-exports Core + Macros)
    .target(
      name: "SwiftSnapshot",
      dependencies: [
        "SwiftSnapshotCore",
        "SwiftSnapshotMacros",
      ],
      path: "Sources/SwiftSnapshot"
    ),

    // Core runtime tests
    .testTarget(
      name: "SwiftSnapshotTests",
      dependencies: [
        "SwiftSnapshot",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),

    // Macro tests
    .testTarget(
      name: "SwiftSnapshotMacrosTests",
      dependencies: [
        "SwiftSnapshotMacros",
        "SwiftSnapshot",
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
