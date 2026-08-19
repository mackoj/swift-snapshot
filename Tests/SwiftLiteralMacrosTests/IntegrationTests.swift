import InlineSnapshotTesting
import SwiftLiteral
import Testing
import SwiftLiteralMacros
@testable import SwiftLiteralCore

// Test types at file level to support extension macros

@SwiftLiteral
struct TestProduct {
  let id: String
  let name: String
}

@SwiftLiteral
struct TestUser {
  let id: String
  @LiteralIgnore
  let cache: [String: Any]
}

@SwiftLiteral
struct TestItem {
  let id: String
  @LiteralRename("displayName")
  let name: String
}

@SwiftLiteral
struct TestSecret {
  let id: String
  @LiteralRedact(.mask("REDACTED"))
  let apiKey: String
}

@SwiftLiteral
struct TestHashRedact {
  let id: String
  @LiteralRedact(.hash)
  let password: String
}

@SwiftLiteral
struct TestOrderedTransforms {
  let id: String
  @LiteralIgnore
  let cache: [String: String]
  @LiteralRedact(.mask("REDACTED"))
  let token: String
  let note: String?
}

@SwiftLiteral
enum TestStatus {
  case active
  case inactive
  case pending
}

// Note: Folder parameter test requires full runtime, skipped in macro-only tests
// @SwiftLiteral(folder: "Fixtures/Test")
// struct TestConfig {
//   let value: String
// }

@SwiftLiteral
enum TestResult {
  case success(value: Int)
  case failure(String)
}

@SwiftLiteral
struct TestGenericContainer<T: Codable> {
  let id: Int
  let items: [T]
}

@SwiftLiteral
struct TestKakou: Codable {
  @LiteralRedact(.mask("1234"))
  let toto: String
  let tata: Val
  enum Val: Codable {
    case a, b, c
  }
}

struct TestUserGeneric<T: Codable> {
  let id: Int
  let name: String
  let some: [T]
}

struct EmptyReflectionFieldsExportable: LiteralFields {
  let id: String
  let alias: String?

  func __swiftLiteral_fields() -> [LiteralField] {
    []
  }
}

extension LiteralTests {
  @Suite struct MacroIntegrationTests {
    init() {
      LiteralConfig.resetToLibraryDefaults()
    }

    /// Assert on what the library writes, not on an intermediate string.
    ///
    /// These tests used to assert on `__swiftSnapshot_makeExpr`, which produced things
    /// like `TestProduct(id: 123, name: Widget)`: unquoted strings, not compilable Swift.
    /// That path is gone. What the file contains is what matters.
    private func generate<T>(_ value: T, as name: String = "fixture") throws -> String {
      try Literal.source(
        of: value,
        named: name)
    }

    @Test func macroAttachesItsMembers() throws {
      #expect(TestProduct.__swiftLiteral_folder == nil)
      #expect(!TestProduct.__swiftLiteral_properties.isEmpty)

      let code = try generate(TestProduct(id: "123", name: "Widget"))
      #expect(code.contains(#"TestProduct(id: "123", name: "Widget")"#))
    }

    @Test func ignoredPropertyIsDropped() throws {
      let code = try generate(TestUser(id: "user123", cache: [:]))

      #expect(code.contains(#"TestUser(id: "user123")"#))
      #expect(!code.contains("cache"))
    }

    @Test func renamedPropertyUsesTheNewLabel() throws {
      let code = try generate(TestItem(id: "item123", name: "Test Item"))

      #expect(code.contains(#"displayName: "Test Item""#))
      #expect(!code.contains("name:"))
    }

    @Test func maskedPropertyIsReplaced() throws {
      let code = try generate(TestSecret(id: "secret123", apiKey: "super-secret-key"))

      #expect(code.contains(#"apiKey: "REDACTED""#))
      #expect(!code.contains("super-secret-key"))
    }

    @Test func hashedPropertyIsReplaced() throws {
      let code = try generate(TestHashRedact(id: "hash123", password: "my-password"))

      #expect(code.contains(#"password: "<hashed>""#))
      #expect(!code.contains("my-password"))
    }

    @Test func enumRendersItsCase() throws {
      let code = try generate(TestStatus.active)

      #expect(code.contains("= .active"))
    }

    @Test func enumRendersAssociatedValues() throws {
      let code = try generate(TestResult.success(value: 42))

      #expect(code.contains(".success(value: 42)"))
    }

    @Test func genericTypesCarryTheirParameters() throws {
      #expect(TestGenericContainer<Int>.__swiftLiteral_folder == nil)
      #expect(!TestGenericContainer<Int>.__swiftLiteral_properties.isEmpty)

      let code = try generate(TestGenericContainer(id: 1, items: [10, 20, 30]))
      #expect(code.contains("id: 1"))
      #expect(code.contains("items: [10, 20, 30]"))
    }

    @Test func targetLevelReflectionExtractionAppliesRedaction() throws {
      let secret = TestSecret(id: "secret123", apiKey: "super-secret-key")

      let code = try Literal.source(
        of: secret,
        named: "testSecret"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension TestSecret {
            static let testSecret: TestSecret = TestSecret(id: "secret123", apiKey: "REDACTED")
        }

        """
      }
    }

    @Test func emptyExtractedFieldsFallbackToMirrorAtTopLevel() throws {
      let value = EmptyReflectionFieldsExportable(id: "abc", alias: nil)

      let code = try Literal.source(
        of: value,
        named: "fixture"
      )

      #expect(code.contains("extension EmptyReflectionFieldsExportable"))
      #expect(code.contains("static let fixture: EmptyReflectionFieldsExportable"))
      #expect(code.contains("id: \"abc\""))
      #expect(code.contains("alias: nil"))
    }

    /// Redaction applies at every depth.
    ///
    /// It used to apply only at the top level, so a secret one struct down was written
    /// to disk in the clear. A redacted property is a secret wherever it sits.
    @Test func redactionAppliesWhenNested() throws {
      struct SecretContainer {
        let secret: TestSecret
      }

      let secret = TestSecret(id: "secret123", apiKey: "super-secret-key")

      let topLevelCode = try Literal.source(
        of: secret,
        named: "topLevelSecret"
      )

      #expect(topLevelCode.contains("extension TestSecret"))
      #expect(topLevelCode.contains("static let topLevelSecret: TestSecret"))
      #expect(topLevelCode.contains("apiKey: \"REDACTED\""))

      let nestedCode = try Literal.source(
        of: SecretContainer(secret: secret),
        named: "nestedSecret"
      )

      #expect(nestedCode.contains("extension SecretContainer"))
      #expect(nestedCode.contains("static let nestedSecret: SecretContainer"))
      #expect(nestedCode.contains("apiKey: \"REDACTED\""))
      #expect(!nestedCode.contains("super-secret-key"))
    }

    @Test func topLevelEnumWithAssociatedValuesRendersViaRuntime() throws {
      let value = TestResult.success(value: 42)

      let code = try Literal.source(
        of: value,
        named: "enumFixture"
      )

      #expect(code.contains("extension TestResult"))
      #expect(code.contains("static let enumFixture: TestResult"))
      #expect(!code.contains("__swiftLiteral_fields"))
    }

    @Test func extractedFieldsApplyTransformsInDeterministicOrder() {
      let value = TestOrderedTransforms(
        id: "user-1",
        cache: ["session": "live"],
        token: "secret-token",
        note: nil
      )

      let fields = value.__swiftLiteral_fields()
      #expect(fields.map(\.label) == ["id", "token", "note"])
      #expect(fields[0].value as? String == "user-1")
      #expect(fields[1].value as? String == "REDACTED")
      #expect(fields[2].value as? String == nil)
    }

    @Test func nestedTypeWithRedaction() throws {
      // This test verifies that when a type with @SwiftLiteral and @LiteralRedact
      // is nested inside another type during export, the redaction is properly applied
      let originalFormatConfigSource = LiteralConfig.getFormatConfigSource()
      let originalFormatProfile = LiteralConfig.formattingProfile()
      defer {
        LiteralConfig.setFormatConfigSource(originalFormatConfigSource)
        LiteralConfig.setFormattingProfile(originalFormatProfile)
      }
      LiteralConfig.setFormatConfigSource(nil)
      LiteralConfig.setFormattingProfile(
        FormatProfile(
          indentStyle: .space,
          indentSize: 4,
          endOfLine: .lf,
          insertFinalNewline: true,
          trimTrailingWhitespace: true
        )
      )
      
      let mockData = [
        TestKakou(toto: "hello", tata: .b),
        TestKakou(toto: "world", tata: .c),
      ]
      
      let user = TestUserGeneric(id: 42, name: "Mack", some: mockData)
      
      let code = try Literal.source(
        of: user,
        named: "mock",
        header: "/// Test HEADER",
        context: "This is for testing."
      )
      
      // Print for manual verification
      print("Generated code:\n\(code)")
      
      assertInlineSnapshot(of: code, as: .description) {
        """
        /// Test HEADER

        import Foundation

        extension TestUserGeneric<TestKakou> {
            /// This is for testing.
            static let mock: TestUserGeneric<TestKakou> = TestUserGeneric<TestKakou>(
                id: 42,
                name: "Mack",
                some: [TestKakou(toto: "1234", tata: .b), TestKakou(toto: "1234", tata: .c)]
            )
        }

        """
      }
    }
  }
}
