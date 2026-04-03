import Testing

@testable import SwiftSnapshotCore

/// US-4 – Class instances with circular references must throw, not hang.
extension SnapshotTests {
  @Suite("US-4 Circular References") struct CircularReferenceTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - Self-referential

    @Test("Self-referential class throws circularReference error")
    func selfReferentialClassThrows() throws {
      final class Node {
        var value: Int
        var next: Node?
        init(_ v: Int) { self.value = v }
      }

      let node = Node(1)
      node.next = node  // circular

      #expect(throws: SwiftSnapshotError.self) {
        _ = try ValueRenderer.render(node, context: SnapshotRenderContext())
      }
    }

    @Test("Mutually-referential classes throw circularReference error")
    func mutuallyReferentialClassesThrow() throws {
      final class A {
        var name: String
        var other: B?
        init(_ n: String) { self.name = n }
      }
      final class B {
        var name: String
        var other: A?
        init(_ n: String) { self.name = n }
      }

      let a = A("a")
      let b = B("b")
      a.other = b
      b.other = a  // mutual cycle

      #expect(throws: SwiftSnapshotError.self) {
        _ = try ValueRenderer.render(a, context: SnapshotRenderContext())
      }
    }

    // MARK: - No false positives

    @Test("Linear chain without cycle renders successfully")
    func linearChainSucceeds() throws {
      final class Node {
        var value: Int
        var next: Node?
        init(_ v: Int) { self.value = v }
      }

      let n1 = Node(1)
      let n2 = Node(2)
      let n3 = Node(3)
      n1.next = n2
      n2.next = n3
      // n3.next == nil – no cycle

      let expr = try ValueRenderer.render(n1, context: SnapshotRenderContext())
      #expect(expr.description.contains("Node("))
    }

    @Test("Plain struct (value type) always renders successfully")
    func plainStructAlwaysSucceeds() throws {
      struct Point { let x: Int; let y: Int }
      let p = Point(x: 1, y: 2)
      let expr = try ValueRenderer.render(p, context: SnapshotRenderContext())
      #expect(expr.description.contains("Point("))
    }

    // MARK: - Error carries context

    @Test("circularReference error description includes type name")
    func circularReferenceErrorHasContext() throws {
      final class Loop {
        var self_ref: Loop?
        init() {}
      }
      let loop = Loop()
      loop.self_ref = loop

      do {
        _ = try ValueRenderer.render(loop, context: SnapshotRenderContext())
        Issue.record("Expected circularReference error to be thrown")
      } catch let error as SwiftSnapshotError {
        #expect(error.description.contains("Loop") || error.description.contains("ircular"))
      }
    }
  }
}
