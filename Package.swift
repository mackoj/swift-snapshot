// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-snapshot",
  platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16)],
  products: [
    .library(
      name: "SwiftLiteral",
      targets: ["SwiftLiteral"]
    ),
    // The rendering engine on its own, for anyone who wants expressions but not files.
    .library(
      name: "SwiftLiteralReflection",
      targets: ["SwiftLiteralReflection"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"604.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format", "509.0.0"..<"604.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.11.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", "1.18.0"..<"1.19.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
  ],
  targets: [
    // Macro implementation (compiler plugin + public macro definitions)
    .macro(
      name: "SwiftLiteralMacros",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
      path: "Sources/SwiftLiteralMacros"
    ),

    // The rendering engine. Value in, ExprSyntax out. No file I/O, no global config.
    .target(
      name: "SwiftLiteralReflection",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
      ],
      path: "Sources/SwiftLiteralReflection"
    ),

    // Configuration, formatting, path resolution, and writing files.
    .target(
      name: "SwiftLiteralCore",
      dependencies: [
        "SwiftLiteralReflection",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftFormat", package: "swift-format"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ],
      path: "Sources/SwiftLiteralCore"
    ),

    // Unified import module (re-exports Core + Macros)
    .target(
      name: "SwiftLiteral",
      dependencies: [
        "SwiftLiteralCore",
        "SwiftLiteralMacros",
      ],
      path: "Sources/SwiftLiteral"
    ),

    // Engine tests. These are the ones that prove the output compiles.
    .testTarget(
      name: "SwiftLiteralReflectionTests",
      dependencies: [
        "SwiftLiteralReflection",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),

    // Core runtime tests
    .testTarget(
      name: "SwiftLiteralTests",
      dependencies: [
        "SwiftLiteral",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
      ]
    ),

    // Macro tests
    .testTarget(
      name: "SwiftLiteralMacrosTests",
      dependencies: [
        "SwiftLiteralMacros",
        "SwiftLiteral",
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility")
]

for index in package.targets.indices {
  package.targets[index].swiftSettings = swiftSettings
}

#if os(macOS)
// Add the documentation compiler plugin if possible
package.dependencies.append(
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
)
#endif
