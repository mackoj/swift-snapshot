import Foundation
import SwiftSyntax

/// A renderer you write yourself, for a type the library cannot figure out.
///
/// Reflection sees stored properties. It does not see memberwise initializers, computed
/// properties, or private storage that the public initializer does not take. When
/// reflection produces the wrong call, write one of these.
///
/// ```swift
/// enum PhoneRenderer: CustomValueRenderer {
///   static func render(_ value: Phone, context: RenderContext) throws -> ExprSyntax {
///     "Phone(e164: \(literal: value.e164))"
///   }
/// }
/// ```
public protocol CustomValueRenderer {
  associatedtype Value
  // `@Sendable` so the function can be bound to a value and handed to the renderer store
  // without dragging the metatype, which is not Sendable, into the closure.
  @Sendable static func render(_ value: Value, context: RenderContext) throws -> ExprSyntax
}

/// The custom renderers in force for a render.
///
/// A value, not a registry. It used to be a singleton with a `shared` instance, which
/// meant a renderer registered by one test was still there in the next one and a suite
/// that only passed in one order looked healthy. Renderers now travel in the
/// ``RenderContext``, so two renders can disagree about how to render a type and neither
/// has to clean up after itself.
///
/// ```swift
/// var renderers = ValueRenderers()
/// renderers.register(Phone.self) { phone, _ in
///   "Phone(e164: \(literal: phone.e164))"
/// }
///
/// let expression = try ValueRenderer.render(
///   value,
///   context: RenderContext(renderers: renderers)
/// )
/// ```
///
/// Lookup is by exact concrete type. A renderer for `Phone` does not apply to a subclass
/// or to a different generic specialisation, but it does cover `Phone?`, because optionals
/// are unwrapped before the renderers are consulted.
public struct ValueRenderers: Sendable {
  private var storage: [ObjectIdentifier: @Sendable (Any, RenderContext) throws -> ExprSyntax] = [:]

  /// No custom renderers. Reflection and the built-ins handle everything.
  public init() {}

  /// Register a closure for one type.
  public mutating func register<Value>(
    _ type: Value.Type,
    render: @escaping @Sendable (Value, RenderContext) throws -> ExprSyntax
  ) {
    storage[ObjectIdentifier(type)] = { value, context in
      guard let typed = value as? Value else {
        throw LiteralError.unsupportedType(
          String(describing: Swift.type(of: value)),
          path: context.path
        )
      }
      return try render(typed, context)
    }
  }

  /// Register a ``CustomValueRenderer``.
  public mutating func register<R: CustomValueRenderer>(_ rendererType: R.Type) {
    // Bind the function up front rather than capturing `R.Type`. A metatype is not
    // Sendable, and the closure is.
    let render: @Sendable (R.Value, RenderContext) throws -> ExprSyntax = R.render
    register(R.Value.self) { value, context in
      try render(value, context)
    }
  }

  /// A copy with one more renderer, for building a set in an expression.
  public func registering<Value>(
    _ type: Value.Type,
    render: @escaping @Sendable (Value, RenderContext) throws -> ExprSyntax
  ) -> ValueRenderers {
    var copy = self
    copy.register(type, render: render)
    return copy
  }

  /// Whether anything is registered.
  public var isEmpty: Bool { storage.isEmpty }

  func renderer(for value: Any) -> ((Any, RenderContext) throws -> ExprSyntax)? {
    storage[ObjectIdentifier(Swift.type(of: value))]
  }
}
