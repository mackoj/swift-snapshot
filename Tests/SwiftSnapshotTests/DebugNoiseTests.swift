import Testing
import InlineSnapshotTesting

@testable import SwiftSnapshotCore

/// US-1 – Verify that rendering on the happy path emits no spurious `reportIssue` calls.
///
/// `reportIssue` is an error-reporting tool; in Swift Testing it records a test failure.
/// Three informational log calls were left in `ValueRenderer` that fire on every
/// successful render. These tests verify those calls are gone.
extension SnapshotTests {
  @Suite("US-1 Debug Noise") struct DebugNoiseTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - Struct rendering

    @Test("Rendering a plain struct emits no spurious issues")
    func renderingPlainStructEmitsNoSpuriousIssues() throws {
      struct Point {
        let x: Int
        let y: Int
      }

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: Point(x: 3, y: 7),
        variableName: "testPoint"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension Point {
            static let testPoint: Point = Point(
                x: 3,
                y: 7
            )
        }

        """
      }
    }

    @Test("Rendering a nested struct emits no spurious issues")
    func renderingNestedStructsEmitsNoSpuriousIssues() throws {
      struct Inner {
        let value: String
      }
      struct Outer {
        let name: String
        let inner: Inner
      }

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: Outer(name: "root", inner: Inner(value: "leaf")),
        variableName: "testOuter"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension Outer {
            static let testOuter: Outer = Outer(
                name: "root",
                inner: Inner(value: "leaf")
            )
        }

        """
      }
    }

    // MARK: - Optional rendering

    @Test("Rendering a non-nil top-level Optional emits no spurious issues")
    func renderingNonNilOptionalEmitsNoSpuriousIssues() throws {
      let value: Int? = 42

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testOptional"
      )

      // The important assertion is that the test reaches here without
      // recorded issues — the snapshot content is a secondary check.
      #expect(code.contains("42"))
    }

    @Test("Rendering a nil top-level Optional emits no spurious issues")
    func renderingNilOptionalEmitsNoSpuriousIssues() throws {
      let value: Int? = nil

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testNilOptional"
      )

      #expect(code.contains("nil"))
    }
  }
}
