import Foundation
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  /// A range renders in its operator form, which swift-format only accepts folded.
  @Suite struct OperatorFormattingTests {
    struct Window {
      let pages: Range<Int>
      let days: ClosedRange<Int>
    }

    /// `Literal.source` stopped the process here: swift-format's "SequenceExpr should have
    /// already been folded".
    @Test func rangesFormat() throws {
      let code = try Literal.source(of: Window(pages: 0..<3, days: 1...5), named: "window")

      #expect(code.contains("pages: 0..<3"))
      #expect(code.contains("days: 1...5"))
    }
  }
}
