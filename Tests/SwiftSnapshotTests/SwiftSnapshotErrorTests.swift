import Foundation
import Testing

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Error messages are part of the API. If they stop naming the type, the path, or the
  /// way out, the user is left guessing.
  @Suite struct SwiftSnapshotErrorTests {
    @Test func unsupportedTypeNamesTheTypeThePathAndTheFix() {
      let error = SwiftSnapshotError.unsupportedType(
        "CustomType", path: ["root", "field", "nested"])

      #expect(
        error.description == """
          Cannot render 'CustomType' at root.field.nested. \
          Register a custom renderer with SnapshotRendererRegistry.register(CustomType.self).
          """
      )
    }

    @Test func unsupportedTypeAtTopLevelHasNoPath() {
      let error = SwiftSnapshotError.unsupportedType("CustomType", path: [])

      #expect(!error.description.contains(" at "))
      #expect(error.description.hasPrefix("Cannot render 'CustomType'."))
    }

    @Test func reflectionCarriesThePath() {
      let error = SwiftSnapshotError.reflection(
        "Cannot reflect type", path: ["User", "address", "zip"])

      #expect(error.description == "Cannot reflect type at User.address.zip")
    }

    @Test func reflectionAtTopLevelHasNoPath() {
      let error = SwiftSnapshotError.reflection("Cannot reflect type", path: [])

      #expect(error.description == "Cannot reflect type")
    }

    @Test func ioPassesTheMessageThrough() {
      #expect(SwiftSnapshotError.io("Failed to write file").description == "Failed to write file")
    }

    @Test func overwriteDisallowedNamesTheFile() {
      let error = SwiftSnapshotError.overwriteDisallowed(URL(fileURLWithPath: "/tmp/test.swift"))

      #expect(error.description == "File exists and overwrite is disallowed: /tmp/test.swift")
    }

    @Test func formattingIsLabelled() {
      let error = SwiftSnapshotError.formatting("Invalid configuration")

      #expect(error.description == "Formatting failed: Invalid configuration")
    }

    @Test func casesAreEquatable() {
      #expect(SwiftSnapshotError.io("test") != SwiftSnapshotError.formatting("test"))
      #expect(SwiftSnapshotError.io("test") == SwiftSnapshotError.io("test"))
    }

    @Test func deepPathsReadInOrder() {
      let error = SwiftSnapshotError.unsupportedType(
        "UnknownType",
        path: ["MyStruct", "nestedArray", "[0]", "deepField", "value"]
      )

      #expect(error.description.contains("MyStruct.nestedArray.[0].deepField.value"))
    }
  }
}
