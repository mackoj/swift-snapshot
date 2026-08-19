import Foundation
import SwiftSyntax
import Testing

@testable import SwiftLiteralReflection

/// Shapes found by rendering the types other reflection libraries test against.
@Suite struct TupleAndFoundationTests {
  private func render(_ value: Any) throws -> String {
    try ValueRenderer.render(value).description
  }

  // MARK: - Tuples

  @Test func unlabelledTuple() throws {
    struct Pair { let value: (Int, String) }

    #expect(try render(Pair(value: (1, "a"))) == #"Pair(value: (1, "a"))"#)
  }

  @Test func labelledTuple() throws {
    struct Point { let value: (x: Int, y: Int) }

    #expect(try render(Point(value: (x: 1, y: 2))) == "Point(value: (x: 1, y: 2))")
  }

  @Test func nestedTuple() throws {
    struct Nested { let value: (Int, (String, Bool)) }

    #expect(try render(Nested(value: (1, ("a", true)))) == #"Nested(value: (1, ("a", true)))"#)
  }

  /// The error message for a type nobody can render used to come out mangled, because the
  /// qualified name of a tuple is `(Swift.Int, Swift.String)` and the renderer split it on
  /// dots as if it were a path.
  @Test func aTupleTypeNameIsNotAPath() throws {
    struct Unrenderable {}
    struct Holder { let value: (Int, Unrenderable, () -> Void) }

    let error = #expect(throws: LiteralError.self) {
      try render(Holder(value: (1, Unrenderable(), {})))
    }

    let description = try #require(error?.description)
    #expect(!description.contains("Swift.String)"))
    #expect(!description.hasPrefix("Cannot render 'Int,"))
  }

  // MARK: - Foundation

  /// `Locale` reflects as a struct with `identifier` and `locale` children, so it used to
  /// render `Locale(identifier: "fr_FR", locale: "fixed fr_FR")`. There is no such
  /// initializer. The library wrote a file that did not compile, which is the one thing it
  /// is supposed to never do.
  @Test func locale() throws {
    #expect(try render(Locale(identifier: "fr_FR")) == #"Locale(identifier: "fr_FR")"#)
  }

  /// `TimeZone` reflects down into an `UnsafePointer`, so it used to throw with a path
  /// four levels deep into Foundation's internals.
  @Test func timeZone() throws {
    let zone = try #require(TimeZone(identifier: "Europe/Paris"))

    #expect(try render(zone) == #"TimeZone(identifier: "Europe/Paris")!"#)
  }

  @Test func localeAndTimeZoneNested() throws {
    struct Settings {
      let locale: Locale
      let zone: TimeZone
    }

    let settings = Settings(
      locale: Locale(identifier: "en_GB"),
      zone: try #require(TimeZone(identifier: "Europe/Paris"))
    )

    #expect(
      try render(settings)
        == #"Settings(locale: Locale(identifier: "en_GB"), zone: TimeZone(identifier: "Europe/Paris")!)"#
    )
  }
}
