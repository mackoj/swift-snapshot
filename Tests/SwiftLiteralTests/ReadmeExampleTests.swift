import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SwiftLiteralCore

// File scope, so these are named the way a real model would be. A type declared inside a
// test function is spelled `(unknown context at $7f…)` by the runtime and renders under its
// short name, which is not what a reader would get.
struct Order {
  struct Line {
    let sku: String
    let quantity: Int
    let unitPrice: Decimal
  }

  enum Status {
    case placed
    case shipped
  }

  let id: UUID
  let placedAt: Date
  let status: Status
  let lines: [Line]
}

extension LiteralTests {
  /// The example in the README, run.
  ///
  /// A README whose output is invented is the same failure as a JSON fixture whose keys are
  /// stale: it looks right, and nobody finds out. This renders the value the README shows
  /// and pins the text it claims, character for character.
  @Suite struct ReadmeExampleTests {
    @Test func theOpeningExampleRendersWhatTheReadmeShows() throws {
      let order = Order(
        id: UUID(uuidString: "8C6D4E2A-0000-4000-8000-1B2C3D4E5F60")!,
        placedAt: Date(timeIntervalSince1970: 1_710_000_000),
        status: .shipped,
        lines: [
          Order.Line(sku: "WDG-001", quantity: 2, unitPrice: Decimal(string: "29.99")!)
        ]
      )

      let code = try Literal.source(of: order, named: "shippedOrder")

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension Order {
            static let shippedOrder: Order = Order(
                id: UUID(uuidString: "8C6D4E2A-0000-4000-8000-1B2C3D4E5F60")!,
                placedAt: Date(timeIntervalSince1970: 1710000000.0),
                status: .shipped,
                lines: [Order.Line(sku: "WDG-001", quantity: 2, unitPrice: Decimal(string: "29.99")!)]
            )
        }

        """
      }
    }
  }
}
