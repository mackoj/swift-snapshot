// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-snapshot",
  platforms: [.macOS(.v13), .iOS(.v15)],
  products: [
    .library(
      name: "SwiftSnapshot",
      targets: ["SwiftSnapshot"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format", from: "600.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftSnapshot",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftFormat", package: "swift-format"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ]
    ),
    .testTarget(
      name: "SwiftSnapshotTests",
      dependencies: ["SwiftSnapshot"]
    ),
  ]
)
