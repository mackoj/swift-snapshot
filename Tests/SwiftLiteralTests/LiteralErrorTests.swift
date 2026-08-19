import Foundation
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  /// Error messages are part of the API. If they stop naming the type, the path, or the
  /// way out, the user is left guessing.
  @Suite struct LiteralErrorTests {
    @Test func unsupportedTypeNamesTheTypeThePathAndTheFix() {
      let error = LiteralError.unsupportedType(
        "CustomType", path: ["root", "field", "nested"])

      #expect(
        error.description == """
          Cannot render 'CustomType' at root.field.nested. \
          Register a custom renderer with LiteralConfig.registerRenderer(CustomType.self).
          """
      )
    }

    @Test func unsupportedTypeAtTopLevelHasNoPath() {
      let error = LiteralError.unsupportedType("CustomType", path: [])

      #expect(!error.description.contains(" at "))
      #expect(error.description.hasPrefix("Cannot render 'CustomType'."))
    }

    @Test func reflectionCarriesThePath() {
      let error = LiteralError.reflection(
        "Cannot reflect type", path: ["User", "address", "zip"])

      #expect(error.description == "Cannot reflect type at User.address.zip")
    }

    @Test func reflectionAtTopLevelHasNoPath() {
      let error = LiteralError.reflection("Cannot reflect type", path: [])

      #expect(error.description == "Cannot reflect type")
    }

    @Test func ioPassesTheMessageThrough() {
      #expect(LiteralError.io("Failed to write file").description == "Failed to write file")
    }

    @Test func overwriteDisallowedNamesTheFile() {
      let error = LiteralError.overwriteDisallowed(URL(fileURLWithPath: "/tmp/test.swift"))

      #expect(error.description == "File exists and overwrite is disallowed: /tmp/test.swift")
    }

    @Test func formattingIsLabelled() {
      let error = LiteralError.formatting("Invalid configuration")

      #expect(error.description == "Formatting failed: Invalid configuration")
    }

    @Test func casesAreEquatable() {
      #expect(LiteralError.io("test") != LiteralError.formatting("test"))
      #expect(LiteralError.io("test") == LiteralError.io("test"))
    }

    @Test func deepPathsReadInOrder() {
      let error = LiteralError.unsupportedType(
        "UnknownType",
        path: ["MyStruct", "nestedArray", "[0]", "deepField", "value"]
      )

      #expect(error.description.contains("MyStruct.nestedArray.[0].deepField.value"))
    }
  }
}
