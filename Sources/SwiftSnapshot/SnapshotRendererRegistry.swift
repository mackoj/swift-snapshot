import Foundation
import SwiftSyntax

/// Protocol for custom snapshot renderers
public protocol SnapshotCustomRenderer {
  associatedtype Value
  static func render(_ value: Value, context: SnapshotRenderContext) throws -> ExprSyntax
}

/// Registry for custom type renderers
public final class SnapshotRendererRegistry {
  static let shared = SnapshotRendererRegistry()

  private var renderers: [ObjectIdentifier: (Any, SnapshotRenderContext) throws -> ExprSyntax] = [:]
  private let lock = NSLock()

  private init() {}

  /// Register a custom renderer for a type
  public static func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
  ) {
    SnapshotRendererRegistry.shared.register(type, render: render)
  }

  /// Register a custom renderer for a type conforming to SnapshotCustomRenderer
  public static func register<SCR: SnapshotCustomRenderer>(
    _ rendererType: SCR.Type
  ) {
    SnapshotRendererRegistry.shared.register(SCR.Value.self) { value, context in
      try SCR.render(value, context: context)
    }
  }

  /// Register a custom renderer for a type
  func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
  ) {
    lock.lock()
    defer { lock.unlock() }

    let id = ObjectIdentifier(type)
    renderers[id] = { value, context in
      guard let typedValue = value as? Value else {
        throw SwiftSnapshotError.unsupportedType(
          String(describing: Swift.type(of: value)),
          path: context.path
        )
      }
      return try render(typedValue, context)
    }
  }

  /// Get a renderer for a value
  func renderer(for value: Any) -> ((Any, SnapshotRenderContext) throws -> ExprSyntax)? {
    lock.lock()
    defer { lock.unlock() }

    let type = Swift.type(of: value)
    let id = ObjectIdentifier(type)
    return renderers[id]
  }
}

/// Bootstrap for built-in renderers
public enum SwiftSnapshotBootstrap {
  private static var hasRegistered = false
  private static let registrationLock = NSLock()

  /// Register default built-in renderers
  public static func registerDefaults() {
    registrationLock.lock()
    defer { registrationLock.unlock() }

    guard !hasRegistered else { return }
    hasRegistered = true
  }
}
