import Foundation
import SwiftSyntax
import Testing

@testable import SwiftLiteralReflection

/// Two shapes an object graph has that a tree of source does not.
@Suite struct GraphShapeTests {
  private class Base {
    var id: Int
    init(id: Int) { self.id = id }
  }

  private final class Derived: Base {
    var name: String
    init(id: Int, name: String) {
      self.name = name
      super.init(id: id)
    }
  }

  private final class Node {
    var name: String
    var peer: Node?
    init(name: String) { self.name = name }
  }

  private func render(_ value: Any) throws -> String {
    try ValueRenderer.render(value).description
  }

  /// `Mirror.children` stops at the class it was made from, so this used to render
  /// `Derived(name: "x")` and lose `id` without saying anything.
  @Test func inheritedPropertiesAreIncluded() throws {
    #expect(try render(Derived(id: 1, name: "x")) == #"Derived(id: 1, name: "x")"#)
  }

  @Test func superclassPropertiesComeFirst() throws {
    let text = try render(Derived(id: 1, name: "x"))
    let idIndex = try #require(text.range(of: "id:"))
    let nameIndex = try #require(text.range(of: "name:"))

    #expect(idIndex.lowerBound < nameIndex.lowerBound)
  }

  /// This used to exhaust the stack and take the test process with it.
  @Test func aCycleThrowsInsteadOfCrashing() throws {
    let a = Node(name: "a")
    let b = Node(name: "b")
    a.peer = b
    b.peer = a

    let error = #expect(throws: LiteralError.self) { try render(a) }

    #expect(error?.description.contains("refers back to itself") == true)
    #expect(error?.description.contains("Node") == true)
  }

  @Test func selfReferenceThrowsToo() throws {
    let node = Node(name: "only")
    node.peer = node

    #expect(throws: LiteralError.self) { try render(node) }
  }

  /// The same object twice in one value is not a cycle. It is two initializer calls, and
  /// the fixture ends up with two objects — see the Limits article.
  @Test func theSameObjectTwiceIsNotACycle() throws {
    struct Pair {
      let left: Node
      let right: Node
    }

    let shared = Node(name: "shared")
    let text = try render(Pair(left: shared, right: shared))

    #expect(text == #"Pair(left: Node(name: "shared", peer: nil), right: Node(name: "shared", peer: nil))"#)
  }
}
