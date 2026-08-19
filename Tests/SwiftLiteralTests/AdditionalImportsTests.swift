import DependenciesTestSupport
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  /// A fixture that mentions a type from another module needs that module imported.
  /// Reflection sees the type name, not where it came from, so the caller says.
  @Suite struct AdditionalImportsTests {
    private struct Empty {}

    private func source(_ imports: [String]) throws -> String {
      try Literal.source(of: Empty(), named: "fixture", additionalImports: imports)
    }

    @Test func noneByDefault() throws {
      let code = try Literal.source(of: 1, named: "fixture")

      #expect(code.contains("import Foundation"))
      #expect(code.components(separatedBy: "import ").count == 2)
    }

    @Test func requestedModulesAreImported() throws {
      let code = try Literal.source(of: 1, named: "fixture", additionalImports: ["MyModels"])

      #expect(code.contains("import Foundation"))
      #expect(code.contains("import MyModels"))
    }

    @Test func orderIsStableAndDuplicatesCollapse() throws {
      let first = try Literal.source(
        of: 1, named: "fixture", additionalImports: ["Zebra", "Apple", "Zebra"])
      let second = try Literal.source(
        of: 1, named: "fixture", additionalImports: ["Apple", "Zebra"])

      #expect(first == second)

      let apple = try #require(first.range(of: "import Apple"))
      let zebra = try #require(first.range(of: "import Zebra"))
      #expect(apple.lowerBound < zebra.lowerBound)
    }
  }
}
