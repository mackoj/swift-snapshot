import Foundation

/// One value, and the type its fixture will be declared as.
///
/// The whole matrix lives here so the snapshot tests and the round-trip typecheck
/// test cover exactly the same ground. Add a case here and both tests pick it up.
struct Sample {
  let name: String
  let type: String
  let value: Any

  init(_ name: String, _ type: String, _ value: Any) {
    self.name = name
    self.type = type
    self.value = value
  }
}

/// The matrix. A function, not a global, so it needs no concurrency ceremony.
func samples() -> [Sample] {
  [
  Sample(
    "primitives", "Primitives",
    Primitives(
      string: "Alice",
      int: 42,
      int8: -8,
      uint64: .max,
      double: 3.25,
      float: 1.5,
      bool: true,
      character: "é"
    )
  ),
  Sample(
    "optionals", "Optionals",
    Optionals(present: "here", absent: nil, nested: nil, nestedSomeNil: .some(nil))
  ),
  Sample(
    "collections", "Collections",
    Collections(
      numbers: [3, 1, 2],
      empty: [],
      byInt: [2: "two", 1: "one"],
      byString: ["b": 2, "a": 1],
      byEnum: [.spades: 1],
      emptyDictionary: [:],
      tags: ["zebra", "apple"],
      emptyTags: [],
      matrix: [[1, 2], [3]]
    )
  ),
  Sample(
    "foundationValues", "FoundationValues",
    FoundationValues(
      date: Date(timeIntervalSince1970: 1_234_567_890),
      uuid: UUID(uuidString: "DEADBEEF-0000-0000-0000-00000000CAFE")!,
      url: URL(string: "https://example.com/a%20path?q=1&r=2")!,
      smallData: Data([0x00, 0x01, 0xFF]),
      largeData: Data(repeating: 0xAB, count: 64),
      decimal: Decimal(string: "12345.6789")!
    )
  ),
  Sample("ranges", "Ranges", Ranges(half: 1..<5, closed: 1...5)),
  Sample(
    "withEnums", "WithEnums",
    WithEnums(
      suit: .spades,
      priority: .high,
      step: .start,
      labelled: .move(x: 1, y: 2),
      unlabelled: .pair(7, "seven"),
      weekday: .tuesday
    )
  ),
  Sample(
    "person", "Person",
    Person(
      name: "Alice",
      address: Address(street: "1 Infinite Loop", city: "Cupertino"),
      previousAddresses: [Address(street: "2 Elm", city: "Paris")]
    )
  ),
  Sample(
    "account", "Account",
    Account(
      id: 7,
      owner: Person(
        name: "Bob",
        address: Address(street: "3 Oak", city: "Lille"),
        previousAddresses: []
      )
    )
  ),
  Sample("form", "Form", Form(title: "  padded  ")),
  Sample("generics", "Generics", Generics(intBox: Box(value: 1), stringBox: Box(value: "x"))),
  Sample(
    "escapes", "Escapes",
    Escapes(
      quotes: #"he said "hi""#,
      backslash: #"C:\path\to"#,
      newline: "line one\nline two",
      tab: "a\tb",
      unicode: "café — naïve",
      emoji: "🇫🇷 shipped 🚀",
      interpolationLookalike: #"\(notInterpolated)"#
    )
  ),
  Sample(
    "extremes", "Extremes",
    Extremes(
      maxInt: .max,
      minInt: .min,
      infinity: .infinity,
      negativeInfinity: -.infinity,
      nan: .nan,
      verySmall: 5e-324,
      integral: 7
    )
  ),
  ]
}
