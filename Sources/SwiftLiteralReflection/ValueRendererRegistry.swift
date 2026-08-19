import Foundation
import SwiftSyntax

/// A renderer you write yourself, for a type the library cannot figure out.
///
/// Reflection sees stored properties. It does not see memberwise initializers,
/// computed properties, or private storage that the public initializer does not
/// take. When reflection produces the wrong call, write one of these.
///
/// ```swift
/// enum PhoneRenderer: CustomValueRenderer {
///   static func render(_ value: Phone, context: RenderContext) throws -> ExprSyntax {
///     "Phone(e164: \(literal: value.e164))"
///   }
/// }
/// ValueRendererRegistry.register(PhoneRenderer.self)
/// ```
public protocol CustomValueRenderer {
  associatedtype Value
  static func render(_ value: Value, context: RenderContext) throws -> ExprSyntax
}

/// Where custom renderers live.
///
/// Lookup is by exact concrete type. A renderer for `Phone` does not apply to
/// `Phone?` or to a subclass; the library unwraps optionals before it looks, so
/// registering the wrapped type is enough.
public final class ValueRendererRegistry: @unchecked Sendable {
  static let shared = ValueRendererRegistry()

  private var renderers: [ObjectIdentifier: (Any, RenderContext) throws -> ExprSyntax] = [:]
  private let lock = NSLock()

  private init() {}

  /// Register a closure for one type.
  public static func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, RenderContext) throws -> ExprSyntax
  ) {
    shared.register(type, render: render)
  }

  /// Register a ``CustomValueRenderer``.
  public static func register<R: CustomValueRenderer>(_ rendererType: R.Type) {
    shared.register(R.Value.self) { value, context in
      try R.render(value, context: context)
    }
  }

  /// Forget every registered renderer.
  ///
  /// The registry is global, so a renderer registered by one test leaks into the
  /// next one. Call this from your test setup.
  public static func removeAll() {
    shared.lock.lock()
    defer { shared.lock.unlock() }
    shared.renderers.removeAll()
  }

  private func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, RenderContext) throws -> ExprSyntax
  ) {
    lock.lock()
    defer { lock.unlock() }
    renderers[ObjectIdentifier(type)] = { value, context in
      guard let typed = value as? Value else {
        throw LiteralError.unsupportedType(
          String(describing: Swift.type(of: value)),
          path: context.path
        )
      }
      return try render(typed, context)
    }
  }

  func renderer(for value: Any) -> ((Any, RenderContext) throws -> ExprSyntax)? {
    lock.lock()
    defer { lock.unlock() }
    return renderers[ObjectIdentifier(Swift.type(of: value))]
  }
}
