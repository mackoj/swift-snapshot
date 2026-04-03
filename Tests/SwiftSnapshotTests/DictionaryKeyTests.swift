import Testing

@testable import SwiftSnapshotCore

/// US-2 – Dictionary keys must preserve their original type.
/// A [Int: String] dict must render with Int key literals, not String literals.
extension SnapshotTests {
  @Suite("US-2 Dictionary Key Types") struct DictionaryKeyTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    @Test("Int keys render as integer literals, not string literals")
    func intKeysRenderAsIntLiterals() throws {
      let dict: [Int: String] = [1: "one", 2: "two"]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: dict,
        variableName: "testIntDict"
      )
      // Keys must appear as integer literals
      #expect(code.contains("1: \"one\"") || code.contains("1: \"two\""))
      // Keys must NOT appear as string literals (old broken behaviour)
      #expect(!code.contains("\"1\":"))
      #expect(!code.contains("\"2\":"))
    }

    @Test("Bool keys render as bool literals")
    func boolKeysRenderAsBoolLiterals() throws {
      let dict: [Bool: String] = [true: "yes", false: "no"]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: dict,
        variableName: "testBoolDict"
      )
      #expect(code.contains("true:") || code.contains("false:"))
      #expect(!code.contains("\"true\":"))
      #expect(!code.contains("\"false\":"))
    }

    @Test("String keys still render correctly (regression)")
    func stringKeysRenderCorrectly() throws {
      let dict: [String: Int] = ["a": 1, "b": 2]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: dict,
        variableName: "testStringDict"
      )
      #expect(code.contains("\"a\": 1") || code.contains("\"b\": 2"))
    }

    @Test("Int keys in a struct property preserve their type")
    func intKeysInsideStructPreserveType() throws {
      struct Wrapper {
        let scores: [Int: String]
      }
      let w = Wrapper(scores: [10: "ten", 20: "twenty"])
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: w,
        variableName: "testWrapper"
      )
      #expect(code.contains("10: \"ten\"") || code.contains("10:"))
      #expect(!code.contains("\"10\":"))
    }
  }
}
