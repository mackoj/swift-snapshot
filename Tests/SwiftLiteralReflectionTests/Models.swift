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

/// A `Collection` the standard library did not write, of the shape `IdentifiedArray` and
/// `OrderedSet` have: one array in, one initializer taking it.
struct Bag<Element>: Collection {
  private let elements: [Element]

  init(_ elements: [Element]) { self.elements = elements }

  var startIndex: Int { elements.startIndex }
  var endIndex: Int { elements.endIndex }
  subscript(position: Int) -> Element { elements[position] }
  func index(after i: Int) -> Int { i + 1 }
}

struct Bags {
  var numbers: Bag<Int>
  var addresses: Bag<Address>
}

/// A subclass. `Mirror.children` stops at the class it was made from, so the renderer has
/// to walk the superclass chain itself or inherited state disappears.
class Vehicle {
  var wheels: Int

  init(wheels: Int) { self.wheels = wheels }
}

final class Car: Vehicle {
  var plate: String

  init(wheels: Int, plate: String) {
    self.plate = plate
    super.init(wheels: wheels)
  }
}

/// A nested type. `String(describing:)` gives only `Line`, which does not resolve from a
/// fixture that lives in an extension on something else.
struct Invoice {
  struct Line {
    var sku: String
    var quantity: Int
  }

  enum State {
    case draft
    case sent
  }

  var state: State
  var lines: [Line]
}

/// Tuples, and the two Foundation types that reflect into something unusable.
///
/// `Locale` reflects with an extra `locale` child that no initializer takes. `TimeZone`
/// reflects down into an `UnsafePointer`.
struct Settings {
  var window: (width: Int, height: Int)
  var origin: (Int, Int)
  var locale: Locale
  var zone: TimeZone
}
