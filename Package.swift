// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-snapshot",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "SwiftSnapshot",
            targets: ["SwiftSnapshot"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftSnapshot",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "IssueReporting", package: "swift-issue-reporting"),
            ]
        ),
        .testTarget(
            name: "SwiftSnapshotTests",
            dependencies: ["SwiftSnapshot"]
        ),
    ]
)
