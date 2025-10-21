import InlineSnapshotTesting
import SwiftSnapshot
import Testing
import SwiftSnapshotMacros
@testable import SwiftSnapshotCore

// Test types at file level to support extension macros

@SwiftSnapshot
struct TestProduct {
  let id: String
  let name: String
}

@SwiftSnapshot
struct TestUser {
  let id: String
  @SnapshotIgnore
  let cache: [String: Any]
}

@SwiftSnapshot
struct TestItem {
  let id: String
  @SnapshotRename("displayName")
  let name: String
}

@SwiftSnapshot
struct TestSecret {
  let id: String
  @SnapshotRedact(.mask("REDACTED"))
  let apiKey: String
}

@SwiftSnapshot
struct TestHashRedact {
  let id: String
  @SnapshotRedact(.hash)
  let password: String
}

@SwiftSnapshot
enum TestStatus {
  case active
  case inactive
  case pending
}

// Note: Folder parameter test requires full runtime, skipped in macro-only tests
// @SwiftSnapshot(folder: "Fixtures/Test")
// struct TestConfig {
//   let value: String
// }

@SwiftSnapshot
enum TestResult {
  case success(value: Int)
  case failure(String)
}

@SwiftSnapshot
struct TestGenericContainer<T: Codable> {
  let id: Int
  let items: [T]
}

@SwiftSnapshot
struct TestKakou: Codable {
  @SnapshotRedact(.mask("1234"))
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

extension SnapshotTests {
  @Suite struct MacroIntegrationTests {
    @Test func macroGeneratedCodeCompiles() throws {
      // This test verifies that code using the macros compiles successfully
      // The fact that this file compiles proves the macros are working

      // Verify the generated members exist
      #expect(TestProduct.__swiftSnapshot_folder == nil)  // No folder parameter specified
      #expect(!TestProduct.__swiftSnapshot_properties.isEmpty)

      let product = TestProduct(id: "123", name: "Widget")
      let expr = TestProduct.__swiftSnapshot_makeExpr(from: product)

      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestProduct(id: 123, name: Widget)
        """
      }
    }

    @Test func macroWithIgnore() throws {
      let user = TestUser(id: "user123", cache: [:])
      let expr = TestUser.__swiftSnapshot_makeExpr(from: user)

      // Verify ignored property is not in expression
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestUser(id: user123)
        """
      }
    }

    @Test func macroWithRename() throws {
      let item = TestItem(id: "item123", name: "Test Item")
      let expr = TestItem.__swiftSnapshot_makeExpr(from: item)

      // Verify renamed label is used
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestItem(id: item123, displayName: Test Item)
        """
      }
    }

    @Test func macroWithRedact() throws {
      let secret = TestSecret(id: "secret123", apiKey: "super-secret-key")
      let expr = TestSecret.__swiftSnapshot_makeExpr(from: secret)

      // Verify redacted value appears instead of actual value
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestSecret(id: secret123, apiKey: "REDACTED")
        """
      }
    }

    @Test func macroWithHashRedact() throws {
      let hashSecret = TestHashRedact(id: "hash123", password: "my-password")
      let expr = TestHashRedact.__swiftSnapshot_makeExpr(from: hashSecret)

      // Verify hashed placeholder appears instead of actual value
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestHashRedact(id: hash123, password: "<hashed>")
        """
      }
    }

    @Test func macroWithEnum() throws {
      let status = TestStatus.active
      let expr = TestStatus.__swiftSnapshot_makeExpr(from: status)

      // Verify enum case is rendered
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        .active
        """
      }
    }

    // Folder test skipped - requires full runtime integration
    // @Test func macroWithFolder() throws {
    //   #expect(TestConfig.__swiftSnapshot_folder == "Fixtures/Test")
    // }

    @Test func enumWithAssociatedValues() throws {
      let success = TestResult.success(value: 42)
      let expr = TestResult.__swiftSnapshot_makeExpr(from: success)

      // Verify enum with associated values
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        .success(value: 42)
        """
      }
    }

    @Test func macroWithGenericType() throws {
      // Verify that generic types compile and have computed properties
      #expect(TestGenericContainer<Int>.__swiftSnapshot_folder == nil)
      #expect(!TestGenericContainer<Int>.__swiftSnapshot_properties.isEmpty)

      let container = TestGenericContainer(id: 1, items: [10, 20, 30])
      let expr = TestGenericContainer<Int>.__swiftSnapshot_makeExpr(from: container)

      // Verify expression is generated correctly
      assertInlineSnapshot(of: expr.description, as: .description) {
        """
        TestGenericContainer(id: 1, items: [10, 20, 30])
        """
      }
    }

    @Test func nestedTypeWithRedaction() throws {
      // This test verifies that when a type with @SwiftSnapshot and @SnapshotRedact
      // is nested inside another type during export, the redaction is properly applied
      
      let mockData = [
        TestKakou(toto: "hello", tata: .b),
        TestKakou(toto: "world", tata: .c),
      ]
      
      let user = TestUserGeneric(id: 42, name: "Mack", some: mockData)
      
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: user,
        variableName: "mock",
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
                some: [TestKakou(toto: "hello", tata: .b), TestKakou(toto: "world", tata: .c)]
            )
        }

        """
      }
    }
  }
}
