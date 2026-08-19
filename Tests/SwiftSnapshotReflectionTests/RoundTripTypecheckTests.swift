import Foundation
import SnapshotTesting
import SwiftSyntax
import Testing

@testable import SwiftSnapshotReflection

/// The only test that proves the pitch.
///
/// Everything else checks that the renderer produces the text we expected. This one
/// hands the text to the compiler, next to the real type declarations, and asks
/// whether it type-checks. Parsing is not enough: `User(name: nil)` parses fine and
/// does not build.
@Suite(.snapshots(record: .missing)) struct RoundTripTypecheckTests {
  @Test func everySampleTypechecks() throws {
    // Locals inside a function, not globals. Global `let`s of non-Sendable types are a
    // concurrency error under Swift 6, and that has nothing to do with the fixture.
    var lines = ["import Foundation", "", "func check() {"]
    for sample in samples() {
      let expression = try ValueRenderer.render(sample.value)
      lines.append("  let \(sample.name): \(sample.type) = \(expression.description)")
      lines.append("  _ = \(sample.name)")
    }
    lines.append("}")
    let generated = lines.joined(separator: "\n") + "\n"

    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("swift-snapshot-roundtrip-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let generatedURL = directory.appendingPathComponent("Generated.swift")
    try generated.write(to: generatedURL, atomically: true, encoding: .utf8)

    // The exact text, pinned. A rendering change should show up in the diff of this
    // file, not go unnoticed because it happens to still compile.
    assertSnapshot(of: generated, as: .lines, named: "fixtures")

    let result = try typecheck([modelsURL, generatedURL])
    #expect(
      result.status == 0,
      """
      Generated fixtures do not compile.

      \(result.output)

      --- Generated.swift ---
      \(generated)
      """
    )
  }

  /// `Models.swift` sits next to this file and holds the type declarations.
  private var modelsURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Models.swift")
  }

  private func typecheck(_ files: [URL]) throws -> (status: Int32, output: String) {
    let process = Process()
    let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")
    if FileManager.default.isExecutableFile(atPath: xcrun.path) {
      process.executableURL = xcrun
      process.arguments = ["swiftc", "-typecheck", "-swift-version", "6"] + files.map(\.path)
    } else {
      process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      process.arguments = ["swiftc", "-typecheck", "-swift-version", "6"] + files.map(\.path)
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self))
  }
}
