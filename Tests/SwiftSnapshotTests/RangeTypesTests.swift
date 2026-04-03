import Testing

@testable import SwiftSnapshotCore

/// US-3 – Range<Bound> and ClosedRange<Bound> must render as 1..<5 and 1...5.
extension SnapshotTests {
  @Suite("US-3 Range Types") struct RangeTypesTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    @Test("Range<Int> renders as open range operator")
    func openRangeOfInt() throws {
      let range: Range<Int> = 1..<5
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: range,
        variableName: "testRange"
      )
      #expect(code.contains("1..<5") || code.contains("1 ..< 5"))
      // Must NOT fall through to Collection rendering (which produces invalid code)
      #expect(!code.contains("Range<Int>(["))
    }

    @Test("ClosedRange<Int> renders as closed range operator")
    func closedRangeOfInt() throws {
      let range: ClosedRange<Int> = 1...5
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: range,
        variableName: "testClosedRange"
      )
      #expect(code.contains("1...5") || code.contains("1 ... 5"))
      #expect(!code.contains("ClosedRange<Int>(["))
    }

    @Test("Range<Double> renders correctly")
    func openRangeOfDouble() throws {
      let range: Range<Double> = 0.5..<1.5
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: range,
        variableName: "testDoubleRange"
      )
      #expect(code.contains("..<"))
      #expect(!code.contains("Range<Double>(["))
    }

    @Test("ClosedRange<Double> renders correctly")
    func closedRangeOfDouble() throws {
      let range: ClosedRange<Double> = 0.5...1.5
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: range,
        variableName: "testClosedDoubleRange"
      )
      #expect(code.contains("..."))
      #expect(!code.contains("ClosedRange<Double>(["))
    }

    @Test("Range<Int> as a struct property renders correctly")
    func rangeInsideStruct() throws {
      struct Pagination {
        let page: Int
        let rows: Range<Int>
      }
      let p = Pagination(page: 1, rows: 0..<20)
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: p,
        variableName: "testPagination"
      )
      #expect(code.contains("0..<20") || code.contains("0 ..< 20"))
    }

    @Test("ClosedRange<String> renders correctly")
    func closedRangeOfString() throws {
      let range: ClosedRange<String> = "a"..."z"
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: range,
        variableName: "testStringRange"
      )
      #expect(code.contains("\"a\"...\"z\"") || code.contains("\"a\" ... \"z\""))
    }
  }
}
