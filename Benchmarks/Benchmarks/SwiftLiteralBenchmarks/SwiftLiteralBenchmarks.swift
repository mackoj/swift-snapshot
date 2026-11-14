import Benchmark
import Foundation
import SwiftLiteral
import SwiftLiteralReflection

// The shapes a fixture is made of: arrays of structs, dictionaries, enums with payloads, optionals, Foundation
// values, and deep nesting. Every value is built once, outside the measured closure.

enum Status: Sendable { case pending, shipped(trackingNumber: String, carrier: String), cancelled(reason: String) }

struct Line: Sendable {
  let sku: String
  let quantity: Int
  let unitPrice: Decimal
}

struct Address: Sendable {
  let street: String
  let city: String
  let postcode: String?
}

struct Order: Sendable {
  let id: UUID
  let placedAt: Date
  let status: Status
  let lines: [Line]
  let shippingAddress: Address
  let tags: Set<String>
  let notes: String?
  let total: Double
}

indirect enum Tree: Sendable {
  case leaf(Int)
  case node(Tree, Tree)
}

final class Node: Sendable {
  let value: Int
  let next: Node?
  init(value: Int, next: Node?) {
    self.value = value
    self.next = next
  }
}

enum Fixtures {
  static func order(_ index: Int) -> Order {
    Order(
      id: UUID(uuidString: String(format: "8C6D4E2A-0000-4000-8000-%012X", index))!,
      placedAt: Date(timeIntervalSince1970: 1_710_000_000 + Double(index)),
      status: index % 3 == 0
        ? .pending
        : index % 3 == 1 ? .shipped(trackingNumber: "1Z\(index)", carrier: "UPS") : .cancelled(reason: "Out of stock"),
      lines: (0..<3).map { Line(sku: "WDG-\($0)", quantity: $0 + 1, unitPrice: Decimal(string: "29.99")!) },
      shippingAddress: Address(street: "\(index) Main Street", city: "Lille", postcode: index % 2 == 0 ? "59000" : nil),
      tags: ["gift", "express", "tag\(index % 5)"],
      notes: index % 4 == 0 ? "Leave at the door.\nRing twice, \"loudly\"." : nil,
      total: 89.97 + Double(index)
    )
  }

  static let orders: [Order] = (0..<1_000).map(order)
  static let ordersByID: [String: Order] = Dictionary(
    uniqueKeysWithValues: (0..<1_000).map { ("order-\($0)", order($0)) })
  static let integers: [Int] = Array(0..<10_000)
  static let strings: [String] = (0..<2_000).map { "Ligne \($0) — café, \"quoted\"\tand\nescaped ✓" }

  static func tree(depth: Int) -> Tree {
    depth == 0 ? .leaf(depth) : .node(tree(depth: depth - 1), .leaf(depth))
  }
  /// 40 levels. Rendering and parsing both recurse once per level, and a benchmark runs on a secondary thread with a
  /// 512 KB stack: 100 levels overflows it inside SwiftParser (docs/performance.md, "Limits").
  static let deepTree = tree(depth: 40)

  static let linkedList: Node = (0..<40).reversed().reduce(nil as Node?) { Node(value: $1, next: $0) }!
}

let benchmarks: @Sendable () -> Void = {
  Benchmark.defaultConfiguration = .init(
    metrics: [.wallClock, .cpuTotal, .mallocCountTotal, .peakMemoryResident, .retainCount],
    maxDuration: .seconds(2),
    maxIterations: 1_000
  )

  // The engine on its own: value in, `ExprSyntax` out.
  Benchmark("Render, 1000 orders") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.orders))
  }
  Benchmark("Render, dictionary of 1000 orders") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.ordersByID))
  }
  Benchmark("Render, 10000 integers") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.integers))
  }
  Benchmark("Render, 2000 strings with escapes") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.strings))
  }
  Benchmark("Render, enum tree 40 deep") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.deepTree))
  }
  Benchmark("Render, class chain 40 deep") { benchmark in
    blackHole(try ValueRenderer.render(Fixtures.linkedList))
  }

  // The whole file: render, build the extension, swift-format, post-process.
  Benchmark("Source, one order") { benchmark in
    blackHole(try Literal.source(of: Fixtures.orders[1], named: "shippedOrder"))
  }
  Benchmark("Source, 1000 orders") { benchmark in
    blackHole(try Literal.source(of: Fixtures.orders, named: "orders"))
  }
}
