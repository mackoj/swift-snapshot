import Foundation
import SwiftSyntax

/// Protocol for custom snapshot renderers
public protocol SnapshotCustomRenderer {
  associatedtype Value
  static func render(_ value: Value, context: SnapshotRenderContext) throws -> ExprSyntax
}

/// Registry for custom type renderers
///
/// **Note**: All public registration methods are only available in DEBUG builds.
/// In release builds, they become no-ops to ensure zero runtime overhead in production.
public final class SnapshotRendererRegistry {
  static let shared = SnapshotRendererRegistry()

  private var renderers: [ObjectIdentifier: (Any, SnapshotRenderContext) throws -> ExprSyntax] = [:]
  private let lock = NSLock()

  private init() {}

  /// Register a custom renderer for a type
  ///
  /// **Debug Only**: This method only operates in DEBUG builds.
  public static func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
  ) {
    #if DEBUG
    SnapshotRendererRegistry.shared.register(type, render: render)
    #endif
  }

  /// Register a custom renderer for a type conforming to SnapshotCustomRenderer
  ///
  /// **Debug Only**: This method only operates in DEBUG builds.
  public static func register<SCR: SnapshotCustomRenderer>(
    _ rendererType: SCR.Type
  ) {
    #if DEBUG
    SnapshotRendererRegistry.shared.register(SCR.Value.self) { value, context in
      try SCR.render(value, context: context)
    }
    #endif
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
///
/// **Note**: All public methods are only available in DEBUG builds.
public enum SwiftSnapshotBootstrap {
  private static var hasRegistered = false
  private static let registrationLock = NSLock()

  /// Register default built-in renderers
  ///
  /// **Debug Only**: This method only operates in DEBUG builds.
  public static func registerDefaults() {
    #if DEBUG
    registrationLock.lock()
    defer { registrationLock.unlock() }

    guard !hasRegistered else { return }
    hasRegistered = true
    #endif
  }
}
