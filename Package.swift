// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-snapshot",
  platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16)],
  products: [
    .library(
      name: "SwiftSnapshot",
      targets: ["SwiftSnapshot"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.7.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
  ],
  targets: [
    // Macro implementation (compiler plugin + public macro definitions)
    .macro(
      name: "SwiftSnapshotMacros",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
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
  ],
  swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility")
  // .unsafeFlags([
  //   "-Xfrontend",
  //   "-warn-long-function-bodies=50",
  //   "-Xfrontend",
  //   "-warn-long-expression-type-checking=50",
  // ])
]

for index in package.targets.indices {
  package.targets[index].swiftSettings = swiftSettings
}

#if !os(Windows)
// Add the documentation compiler plugin if possible
package.dependencies.append(
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
)
#endif
