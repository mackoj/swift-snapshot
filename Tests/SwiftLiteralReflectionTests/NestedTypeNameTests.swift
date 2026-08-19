import Foundation
import SwiftSyntax
import Testing

@testable import SwiftLiteralReflection

/// What name a nested type renders under.
///
/// The renderer takes `String(describing: type(of: value))`. For a type declared at file
/// scope that is the name you wrote. For a nested one it is not always qualified, and an
/// unqualified name only resolves if the fixture happens to sit in a scope that can see it.
@Suite struct NestedTypeNameTests {
  @Test func topLevelTypesRenderTheirName() throws {
    let text = try ValueRenderer.render(Outer(id: 1)).description
    #expect(text == "Outer(id: 1)")
  }

  @Test func nestedTypesRenderQualified() throws {
    let text = try ValueRenderer.render(Outer.Inner(name: "a")).description
    #expect(text == #"Outer.Inner(name: "a")"#, "got \(text)")
  }

  @Test func aNestedValueInsideItsOwnerRendersQualified() throws {
    let text = try ValueRenderer.render(Owner(inner: Outer.Inner(name: "b"))).description
    #expect(text == #"Owner(inner: Outer.Inner(name: "b"))"#, "got \(text)")
  }
}

// File scope, so these are named the way a real model would be.
struct Outer {
  let id: Int

  struct Inner {
    let name: String
  }
}

struct Owner {
  let inner: Outer.Inner
}
