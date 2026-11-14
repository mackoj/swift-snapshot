// swift-tools-version: 6.0
import PackageDescription

// swift-snapshot's benchmarks, on ordo-one/benchmark (https://www.swift.org/blog/benchmarks/). A separate
// package so the library's users never build the benchmark dependency. Run from the repository root:
// `swift package --package-path Benchmarks benchmark`. Needs jemalloc (`brew install jemalloc`) for malloc counts.
let package = Package(
  name: "Benchmarks",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(name: "swift-snapshot", path: ".."),
    .package(url: "https://github.com/ordo-one/benchmark.git", from: "1.38.0"),
  ],
  targets: [
    .executableTarget(
      name: "SwiftLiteralBenchmarks",
      dependencies: [
        .product(name: "Benchmark", package: "benchmark"),
        .product(name: "SwiftLiteral", package: "swift-snapshot"),
        .product(name: "SwiftLiteralReflection", package: "swift-snapshot"),
      ],
      path: "Benchmarks/SwiftLiteralBenchmarks",
      plugins: [
        .plugin(name: "BenchmarkPlugin", package: "benchmark")
      ]
    ),
    // Reads two `benchmark --format markdown` outputs and prints each benchmark's p50 before and after.
    .executableTarget(name: "p50", path: "Tools/P50"),
    // Reads an exported Time Profiler table and prints the hottest functions (scripts/profile.sh).
    .executableTarget(name: "hotspots", path: "Tools/Hotspots"),
  ]
)
