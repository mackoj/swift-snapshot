import Foundation
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  /// DocC links cannot cross the module boundary reliably.
  ///
  /// A ` ``Symbol`` ` in `SwiftLiteralCore` naming a type from `SwiftLiteralReflection`
  /// resolves on some toolchains and fails on others. It passed locally on Swift 6.4 and
  /// failed CI, twice, which is the worst way to find out.
  ///
  /// Cross-module references are code spans here: `` `RenderContext` ``, not
  /// ` ``RenderContext`` `. This test is the guard, and it costs milliseconds instead of a
  /// documentation build.
  @Suite struct DocLinkTests {
    private var sources: URL {
      URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // SwiftLiteralTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // package root
        .appendingPathComponent("Sources")
    }

    private func swiftAndMarkdownFiles(under directory: URL) throws -> [URL] {
      guard
        let walker = FileManager.default.enumerator(
          at: directory, includingPropertiesForKeys: nil)
      else { return [] }

      return walker.compactMap { $0 as? URL }
        .filter { ["swift", "md"].contains($0.pathExtension) }
    }

    /// Every public type name the reflection module exports.
    private func reflectionSymbols() throws -> Set<String> {
      let declaration = /public (?:struct|enum|final class|class|protocol) (\w+)/
      var names: Set<String> = []

      for file in try swiftAndMarkdownFiles(
        under: sources.appendingPathComponent("SwiftLiteralReflection"))
      where file.pathExtension == "swift" {
        let text = try String(contentsOf: file, encoding: .utf8)
        for match in text.matches(of: declaration) {
          names.insert(String(match.1))
        }
      }
      return names
    }

    @Test func coreDoesNotLinkToReflectionSymbols() throws {
      let symbols = try reflectionSymbols()
      #expect(!symbols.isEmpty, "Found no public types in SwiftLiteralReflection to check against")

      var offenders: [String] = []
      for file in try swiftAndMarkdownFiles(
        under: sources.appendingPathComponent("SwiftLiteralCore"))
      {
        let text = try String(contentsOf: file, encoding: .utf8)
        for symbol in symbols where text.contains("``\(symbol)") {
          offenders.append("\(file.lastPathComponent): ``\(symbol)``")
        }
      }

      #expect(
        offenders.isEmpty,
        """
        These cross-module DocC links will fail the documentation build on some toolchains. \
        Use a code span instead:

        \(offenders.joined(separator: "\n"))
        """
      )
    }
  }
}
