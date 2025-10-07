import InlineSnapshotTesting
import Testing
import SwiftSyntaxBuilder

@testable import SwiftSnapshotCore

extension SnapshotTests {
  @Suite struct NestedRedactionTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    @Test func nestedTypeWithRedaction() throws {
      // This test demonstrates the issue: when a type with @SwiftSnapshot
      // and @SnapshotRedact is nested inside another type during export,
      // the redaction should still be applied.
      
      // Define the inner type with redaction (simulating @SwiftSnapshot macro)
      struct Kakou {
        let toto: String
        let tata: Val
        enum Val: Codable {
          case a, b, c
        }
      }
      
      // Define the outer generic type
      struct User<T> {
        let id: Int
        let name: String
        let some: [T]
      }
      
      let mockData = [
        Kakou(toto: "hello", tata: .b),
        Kakou(toto: "world", tata: .c),
      ]
      
      let user = User(id: 42, name: "Mack", some: mockData)
      
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: user,
        variableName: "mock",
        header: "/// Test HEADER",
        context: "This is for testing."
      )
      
      // For now, this will show the current behavior (without redaction)
      // After the fix, the toto fields should be redacted to "1234"
      print("Generated code:\n\(code)")
      
      // The expected output should have redacted values
      // e.g., Kakou(toto: "1234", tata: .b) instead of Kakou(toto: "hello", tata: .b)
    }
  }
}
