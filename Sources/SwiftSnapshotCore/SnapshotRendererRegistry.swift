import Foundation
import SwiftSyntax
import IssueReporting

/// Protocol for custom snapshot renderers
///
/// Types conforming to `SnapshotCustomRenderer` can be registered with ``SnapshotRendererRegistry``
/// to provide custom rendering logic for specific types.
///
/// ## Example
///
/// ```swift
/// struct MyCustomRenderer: SnapshotCustomRenderer {
///     typealias Value = MyType
///
///     static func render(_ value: MyType, context: SnapshotRenderContext) throws -> ExprSyntax {
///         ExprSyntax(stringLiteral: "MyType(value: \"\(value.value)\")")
///     }
/// }
///
/// // Register the renderer
/// SnapshotRendererRegistry.register(MyCustomRenderer.self)
/// ```
public protocol SnapshotCustomRenderer {
  /// The type that this renderer handles
  associatedtype Value
  
  /// Render a value of this type to Swift syntax
  ///
  /// - Parameters:
  ///   - value: The value to render
  ///   - context: Rendering context with formatting and path information
  ///
  /// - Returns: SwiftSyntax expression representing the value
  ///
  /// - Throws: ``SwiftSnapshotError`` if rendering fails
  static func render(_ value: Value, context: SnapshotRenderContext) throws -> ExprSyntax
}

/// Registry for custom type renderers
///
/// `SnapshotRendererRegistry` allows registering custom rendering logic for types that cannot
/// be handled by the built-in ``ValueRenderer``. This is essential for:
/// - Types with complex initialization
/// - Types requiring custom string representations
/// - Types where default reflection produces suboptimal output
///
/// ## Overview
///
/// Custom renderers are checked before built-in renderers, allowing you to override
/// default behavior for any type.
///
/// ## Example - Simple Registration
///
/// ```swift
/// struct CustomType {
///     let value: String
/// }
///
/// SnapshotRendererRegistry.register(CustomType.self) { value, context in
///     ExprSyntax(stringLiteral: """
///     CustomType(value: "\(value.value)")
///     """)
/// }
/// ```
///
/// ## Example - Protocol-Based Registration
///
/// ```swift
/// struct DateRenderer: SnapshotCustomRenderer {
///     typealias Value = Date
///
///     static func render(_ value: Date, context: SnapshotRenderContext) throws -> ExprSyntax {
///         ExprSyntax(stringLiteral: "Date(timeIntervalSince1970: \(value.timeIntervalSince1970))")
///     }
/// }
///
/// SnapshotRendererRegistry.register(DateRenderer.self)
/// ```
///
/// ## Thread Safety
///
/// All registration and lookup methods are thread-safe and can be called concurrently.
///
/// ## See Also
/// - ``ValueRenderer`` for built-in rendering logic
/// - ``SnapshotRenderContext`` for context passed to renderers
///
/// **Note**: All public registration methods are only available in DEBUG builds.
/// In release builds, they become no-ops to ensure zero runtime overhead in production.
public final class SnapshotRendererRegistry: @unchecked Sendable {
  static let shared = SnapshotRendererRegistry()

  private var renderers: [ObjectIdentifier: (Any, SnapshotRenderContext) throws -> ExprSyntax] = [:]
  private let lock = NSLock()

  private init() {}

  /// Register a custom renderer for a type
  ///
  /// Registers a closure-based renderer for the specified type. The renderer will be
  /// invoked by ``ValueRenderer`` when encountering values of this type.
  ///
  /// ## Example
  ///
  /// ```swift
  /// SnapshotRendererRegistry.register(Date.self) { date, context in
  ///     ExprSyntax(stringLiteral: "Date(timeIntervalSince1970: \(date.timeIntervalSince1970))")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - type: The type to register a renderer for
  ///   - render: Closure that converts a value to SwiftSyntax expression
  ///
  /// **Debug Only**: This method only operates in DEBUG builds.
  public static func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
  ) {
    #if DEBUG
    SnapshotRendererRegistry.shared.register(type, render: render)
    #else
    reportIssue("SnapshotRendererRegistry.register() called in release build. Custom renderer registration should only be used in DEBUG builds.")
    #endif
  }

  /// Register a custom renderer for a type conforming to SnapshotCustomRenderer
  ///
  /// Registers a protocol-based renderer. This provides a more structured approach
  /// compared to closure-based registration.
  ///
  /// ## Example
  ///
  /// ```swift
  /// struct URLRenderer: SnapshotCustomRenderer {
  ///     typealias Value = URL
  ///
  ///     static func render(_ value: URL, context: SnapshotRenderContext) throws -> ExprSyntax {
  ///         ExprSyntax(stringLiteral: "URL(string: \"\(value.absoluteString)\")!")
  ///     }
  /// }
  ///
  /// SnapshotRendererRegistry.register(URLRenderer.self)
  /// ```
  ///
  /// - Parameter rendererType: The renderer type conforming to ``SnapshotCustomRenderer``
  ///
  /// **Debug Only**: This method only operates in DEBUG builds.
  public static func register<SCR: SnapshotCustomRenderer>(
    _ rendererType: SCR.Type
  ) {
    #if DEBUG
    SnapshotRendererRegistry.shared.register(SCR.Value.self) { value, context in
      try SCR.render(value, context: context)
    }
    #else
    reportIssue("SnapshotRendererRegistry.register() called in release build. Custom renderer registration should only be used in DEBUG builds.")
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
  private nonisolated(unsafe) static var hasRegistered = false
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
    #else
    reportIssue("SwiftSnapshotBootstrap.registerDefaults() called in release build. Renderer registration should only be used in DEBUG builds.")
    #endif
  }
}
