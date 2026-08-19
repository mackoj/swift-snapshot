import Testing
@testable import SwiftLiteralCore
import InlineSnapshotTesting

extension LiteralTests {
  @Suite struct ManualSanitizationVerification {
    init() {
      // Reset configuration between tests
      LiteralConfig.resetToLibraryDefaults()
    }

    // This test demonstrates the actual behavior of variable name sanitization
    @Test func demonstrateSanitization() throws {
      // Test 1: Valid name remains unchanged
      do {
        let code = try Literal.source(
        of: 42,
        named: "myTestValue"
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let myTestValue: Int = 42 }

          """
        }
        print("✓ Valid name 'myTestValue' remains unchanged")
      }

      // Test 2: Spaces are replaced with underscores
      do {
        let code = try Literal.source(
        of: 42,
        named: "my test value"
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let my_test_value: Int = 42 }

          """
        }
        print("✓ 'my test value' → 'my_test_value'")
      }

      // Test 3: Starting with number gets underscore prefix
      do {
        let code = try Literal.source(
        of: 42,
        named: "123test"
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let _123test: Int = 42 }

          """
        }
        print("✓ '123test' → '_123test'")
      }

      // Test 4: Swift keywords wrapped in backticks
      do {
        let code = try Literal.source(
        of: 42,
        named: "class"
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let `class`: Int = 42 }

          """
        }
        print("✓ 'class' → '`class`'")
      }

      // Test 5: Special characters replaced with underscores
      do {
        let code = try Literal.source(
        of: 42,
        named: "test@value#123"
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let test_value_123: Int = 42 }

          """
        }
        print("✓ 'test@value#123' → 'test_value_123'")
      }

      // Test 6: Empty string becomes underscore
      do {
        let code = try Literal.source(
        of: 42,
        named: ""
        )
        assertInlineSnapshot(of: code, as: .description) {
          """
          import Foundation

          extension Int { static let _: Int = 42 }

          """
        }
        print("✓ '' → '_'")
      }

      print("\n✓✓✓ All sanitization behaviors verified ✓✓✓")
    }
  }
}
