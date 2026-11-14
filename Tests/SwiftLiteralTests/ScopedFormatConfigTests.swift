import Dependencies
import Foundation
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  /// A format config scoped with `withDependencies` applies whole, without touching `LiteralConfig`.
  @Suite struct ScopedFormatConfigTests {
    struct Point { let x: Int; let y: Int }

    /// `{"tabs": 1}` is a setting `FormatProfile` does not carry, so only the full
    /// `.swift-format` configuration can produce a tab.
    @Test func scopedSwiftFormatFileAppliesWhole() throws {
      let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ScopedFormatConfigTests-\(UUID().uuidString)")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: directory) }
      let url = directory.appendingPathComponent(".swift-format")
      try #"{"version": 1, "indentation": {"tabs": 1}}"#.write(to: url, atomically: true, encoding: .utf8)

      let code = try withDependencies {
        $0.literalConfiguration.formatConfigSource = { .swiftFormat(url) }
      } operation: {
        try Literal.source(of: Point(x: 1, y: 2), named: "origin")
      }

      #expect(code.contains("\n\tstatic let origin"))
    }
  }
}
