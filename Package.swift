// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "swift-snapshot",
  platforms: [.macOS(.v13), .iOS(.v15)],
  products: [
    .library(
      name: "SwiftSnapshot",
      targets: ["SwiftSnapshot", "SwiftSnapshotMacros"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
  ],
  targets: [
    // Macro implementation (compiler plugin)
    .macro(
      name: "SwiftSnapshotMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
      path: "Sources/SwiftSnapshotMacrosPlugin"
    ),
    
    // Macro interface (public types and attributes)
    .target(
      name: "SwiftSnapshotMacros",
      dependencies: ["SwiftSnapshotMacrosPlugin"],
      path: "Sources/SwiftSnapshotMacros"
    ),
    
    // Runtime library
    .target(
      name: "SwiftSnapshot",
      dependencies: [
        "SwiftSnapshotMacros",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftFormat", package: "swift-format"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    
    // Runtime tests
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
        "SwiftSnapshotMacrosPlugin",
        "SwiftSnapshotMacros",
        "SwiftSnapshot",
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
