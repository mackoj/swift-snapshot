import Foundation

// The types the renderer is tested against.
//
// This file is compiled twice. Once as part of the test target, so the tests can build
// real values. Once by `swiftc`, alongside the generated fixtures, so the round-trip
// test can prove the generated source type-checks against these exact declarations.
//
// Keep it free of imports beyond Foundation, and free of anything the test target
// needs but a bare `swiftc -typecheck` would not have.

struct Primitives {
  var string: String
  var int: Int
  var int8: Int8
  var uint64: UInt64
  var double: Double
  var float: Float
  var bool: Bool
  var character: Character
}

struct Optionals {
  var present: String?
  var absent: String?
  var nested: Int??
  var nestedSomeNil: Int??
}

struct Collections {
  var numbers: [Int]
  var empty: [String]
  var byInt: [Int: String]
  var byString: [String: Int]
  var byEnum: [Suit: Int]
  var emptyDictionary: [String: String]
  var tags: Set<String>
  var emptyTags: Set<Int>
  var matrix: [[Int]]
}

struct FoundationValues {
  var date: Date
  var uuid: UUID
  var url: URL
  var smallData: Data
  var largeData: Data
  var decimal: Decimal
}

struct Ranges {
  var half: Range<Int>
  var closed: ClosedRange<Int>
}

enum Suit: String, CaseIterable {
  case hearts
  case spades
}

enum Priority: Int {
  case low = 1
  case high = 10
}

enum Step {
  case start
  case retry(Int)
  case move(x: Int, y: Int)
  case pair(Int, String)
}

/// An enum whose `description` is nothing like its case name. `String(describing:)`
/// cannot be trusted here, and that is the point.
enum Weekday: String, CustomStringConvertible {
  case monday
  case tuesday

  var description: String { "a weekday, obviously" }
}

struct WithEnums {
  var suit: Suit
  var priority: Priority
  var step: Step
  var labelled: Step
  var unlabelled: Step
  var weekday: Weekday
}

struct Address {
  var street: String
  var city: String
}

struct Person {
  var name: String
  var address: Address
  var previousAddresses: [Address]
}

final class Account {
  var id: Int
  var owner: Person

  init(id: Int, owner: Person) {
    self.id = id
    self.owner = owner
  }
}

@propertyWrapper
struct Trimmed {
  var wrappedValue: String
}

struct Form {
  @Trimmed var title: String

  init(title: String) {
    self.title = title
  }
}

struct Box<Value> {
  var value: Value
}

struct Generics {
  var intBox: Box<Int>
  var stringBox: Box<String>
}

struct Escapes {
  var quotes: String
  var backslash: String
  var newline: String
  var tab: String
  var unicode: String
  var emoji: String
  var interpolationLookalike: String
}

struct Extremes {
  var maxInt: Int
  var minInt: Int
  var infinity: Double
  var negativeInfinity: Double
  var nan: Double
  var verySmall: Double
  var integral: Double
}
