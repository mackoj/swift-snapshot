import SwiftParser
import SwiftParserDiagnostics
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  @Suite struct GeneratedCodeValidityTests {
    @Test func generatedCodeParsesWithoutDiagnostics() throws {
      struct Address {
        let street: String
        let city: String
      }
      struct User {
        let id: Int
        let name: String
        let address: Address
      }

      let user = User(
        id: 1,
        name: "Alice",
        address: Address(street: "1 Infinite Loop", city: "Cupertino")
      )

      let code = try Literal.source(
        of: user,
        named: "testUser"
      )

      let syntax = Parser.parse(source: code)
      let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: syntax)
      #expect(diagnostics.isEmpty, "Generated code has parse diagnostics: \(diagnostics)")
    }
  }
}
