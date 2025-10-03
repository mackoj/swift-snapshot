import Testing
@testable import SwiftSnapshot

extension SnapshotTests {
  @Suite struct VariableNameSanitizationTests {
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - Basic Sanitization Tests

    @Test func validNameUnchanged() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "testValue"
      )
      #expect(code.contains("static let testValue: Int = 42"))
    }

    @Test func validNameWithNumbers() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test123Value"
      )
      #expect(code.contains("static let test123Value: Int = 42"))
    }

    @Test func validNameWithUnderscore() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test_value"
      )
      #expect(code.contains("static let test_value: Int = 42"))
    }

    @Test func validNameStartingWithUnderscore() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "_testValue"
      )
      #expect(code.contains("static let _testValue: Int = 42"))
    }

    // MARK: - Sanitization Tests - Special Characters

    @Test func nameWithSpaces() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test value"
      )
      #expect(code.contains("static let test_value: Int = 42"))
    }

    @Test func nameWithHyphens() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test-value"
      )
      #expect(code.contains("static let test_value: Int = 42"))
    }

    @Test func nameWithDots() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test.value"
      )
      #expect(code.contains("static let test_value: Int = 42"))
    }

    @Test func nameWithMultipleSpecialChars() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "test@value#123"
      )
      #expect(code.contains("static let test_value_123: Int = 42"))
    }

    // MARK: - Sanitization Tests - Starting with Invalid Characters

    @Test func nameStartingWithNumber() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "123test"
      )
      #expect(code.contains("static let _123test: Int = 42"))
    }

    @Test func nameStartingWithSpecialChar() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "@test"
      )
      #expect(code.contains("static let _test: Int = 42"))
    }

    // MARK: - Sanitization Tests - Swift Keywords

    @Test func swiftKeywordClass() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "class"
      )
      #expect(code.contains("static let `class`: Int = 42"))
    }

    @Test func swiftKeywordStruct() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "struct"
      )
      #expect(code.contains("static let `struct`: Int = 42"))
    }

    @Test func swiftKeywordFunc() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "func"
      )
      #expect(code.contains("static let `func`: Int = 42"))
    }

    @Test func swiftKeywordVar() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "var"
      )
      #expect(code.contains("static let `var`: Int = 42"))
    }

    @Test func swiftKeywordLet() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "let"
      )
      #expect(code.contains("static let `let`: Int = 42"))
    }

    @Test func swiftKeywordReturn() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "return"
      )
      #expect(code.contains("static let `return`: Int = 42"))
    }

    // MARK: - Edge Cases

    @Test func emptyName() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: ""
      )
      #expect(code.contains("static let _: Int = 42"))
    }

    @Test func onlySpecialChars() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "@#$%"
      )
      #expect(code.contains("static let _: Int = 42"))
    }

    @Test func onlyNumbers() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "123"
      )
      #expect(code.contains("static let _123: Int = 42"))
    }

    @Test func mixedCasePreserved() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "testValue"
      )
      #expect(code.contains("static let testValue: Int = 42"))
    }

    // MARK: - Unicode Tests

    @Test func unicodeInName() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "testValue🚀"
      )
      // Unicode should be replaced with underscore
      #expect(code.contains("static let testValue_: Int = 42"))
    }

    // MARK: - Real-world Examples

    @Test func camelCase() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "myTestValue"
      )
      #expect(code.contains("static let myTestValue: Int = 42"))
    }

    @Test func snakeCase() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "my_test_value"
      )
      #expect(code.contains("static let my_test_value: Int = 42"))
    }

    @Test func pascalCase() throws {
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "MyTestValue"
      )
      #expect(code.contains("static let MyTestValue: Int = 42"))
    }
  }
}
