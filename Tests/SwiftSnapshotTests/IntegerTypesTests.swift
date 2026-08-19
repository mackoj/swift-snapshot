import Foundation
import Testing

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Sized integers render as plain literals.
  ///
  /// `Int8(42)` and `42` mean the same thing wherever an `Int8` is expected, and the
  /// short one reads better in a fixture. The round-trip typecheck test in
  /// `SwiftSnapshotReflectionTests` is what proves the literal still lands as an `Int8`.
  @Suite struct IntegerTypesTests {
    private func generate<T>(_ value: T) throws -> String {
      try SwiftSnapshotRuntime.generateSwiftCode(instance: value, variableName: "fixture")
    }

    @Test func signedIntegersRenderAsLiterals() throws {
      #expect(try generate(Int8(42)).contains("= 42"))
      #expect(try generate(Int16(1000)).contains("= 1000"))
      #expect(try generate(Int32(100_000)).contains("= 100000"))
      #expect(try generate(Int64.max).contains("9_223_372_036_854_775_807"))
    }

    @Test func unsignedIntegersRenderAsLiterals() throws {
      #expect(try generate(UInt(42)).contains("= 42"))
      #expect(try generate(UInt8(255)).contains("= 255"))
      #expect(try generate(UInt16(65535)).contains("= 65535"))
      #expect(try generate(UInt64.max).contains("18_446_744_073_709_551_615"))
    }

    @Test func theDeclaredTypeIsStillTheRealType() throws {
      // The extension is on the concrete type, so the literal cannot widen by accident.
      #expect(try generate(Int8(42)).contains("extension Int8"))
      #expect(try generate(UInt64(0)).contains("extension UInt64"))
    }

    @Test func negativeAndZero() throws {
      #expect(try generate(Int32(-42)).contains("= -42"))
      #expect(try generate(UInt64(0)).contains("= 0"))
    }

    @Test func arraysOfSizedIntegers() throws {
      let code = try generate([UInt64(1), 2, 3])
      #expect(code.contains("[1, 2, 3]"))
    }

    @Test func mixedIntegerTypesInOneStruct() throws {
      struct Sizes {
        let small: Int8
        let medium: Int32
        let large: UInt64
      }

      let code = try generate(Sizes(small: -1, medium: 2, large: 3))
      #expect(code.contains("small: -1"))
      #expect(code.contains("medium: 2"))
      #expect(code.contains("large: 3"))
    }
  }
}
