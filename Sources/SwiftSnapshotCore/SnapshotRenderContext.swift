import Foundation
import Dependencies

/// Context provided to custom renderers
///
/// `SnapshotRenderContext` carries configuration and state information through the
/// rendering process. It's passed to all custom renderers via ``SnapshotRendererRegistry``
/// and used internally by ``ValueRenderer``.
///
/// ## Overview
///
/// The context provides:
/// - **Path tracking**: Breadcrumb trail showing the current location in the object graph
/// - **Formatting**: Code formatting settings from ``FormatProfile``
/// - **Options**: Rendering behavior from ``RenderOptions``
///
/// ## Path Tracking
///
/// The `path` property helps with error reporting by showing where in a nested structure
/// an error occurred:
///
/// ```swift
/// // For: user.address.city
/// // Path would be: ["address", "city"]
/// ```
///
/// This is especially useful for ``SwiftSnapshotError/unsupportedType(_:path:)`` errors.
///
/// ## Example - Custom Renderer
///
/// ```swift
/// SnapshotRendererRegistry.register(MyType.self) { value, context in
///     // Access formatting
///     let indent = context.formatting.indent(level: 1)
///
///     // Access render options
///     if context.options.sortDictionaryKeys {
///         // Sort keys...
///     }
///
///     // Check current path for debugging
///     print("Rendering at path: \(context.path.joined(separator: "."))")
///
///     return ExprSyntax(stringLiteral: "MyType(...)")
/// }
/// ```
///
/// ## See Also
/// - ``FormatProfile`` for formatting configuration
/// - ``RenderOptions`` for rendering behavior
/// - ``SnapshotRendererRegistry`` for custom renderer registration
public struct SnapshotRenderContext {
  /// Breadcrumb path within the object graph
  ///
  /// Tracks the property names traversed to reach the current value.
  /// Used for error reporting and debugging.
  ///
  /// ## Example
  ///
  /// When rendering `user.profile.address.city`, the path would be:
  /// ```swift
  /// ["profile", "address", "city"]
  /// ```
  public let path: [String]

  /// Formatting profile to use
  ///
  /// Contains code formatting settings like indentation, line endings, and whitespace rules.
  /// See ``FormatProfile`` for available options.
  public let formatting: FormatProfile

  /// Render options
  ///
  /// Controls rendering behavior like dictionary key sorting, set ordering, and Data thresholds.
  /// See ``RenderOptions`` for available options.
  public let options: RenderOptions

  /// Creates a render context with specified configuration
  ///
  /// If `formatting` or `options` are not provided, values are loaded from
  /// ``SwiftSnapshotConfig`` via dependency injection.
  ///
  /// - Parameters:
  ///   - path: Breadcrumb path (default: empty array)
  ///   - formatting: Optional format profile (default: from config)
  ///   - options: Optional render options (default: from config)
  public init(
    path: [String] = [],
    formatting: FormatProfile? = nil,
    options: RenderOptions? = nil
  ) {
    @Dependency(\.swiftSnapshotConfig) var snapshotConfig
    self.path = path
    self.formatting = formatting ?? snapshotConfig.getFormatProfile()
    self.options = options ?? snapshotConfig.getRenderOptions()
  }

  /// Create a new context with an additional path component
  ///
  /// Used internally by ``ValueRenderer`` when traversing nested structures.
  /// Each level of nesting adds a component to track the full path.
  ///
  /// - Parameter component: The property or index name to append
  /// - Returns: New context with extended path
  ///
  /// ## Example
  ///
  /// ```swift
  /// let parentContext = SnapshotRenderContext(path: ["user", "profile"])
  /// let childContext = parentContext.appending(path: "address")
  /// // childContext.path == ["user", "profile", "address"]
  /// ```
  func appending(path component: String) -> SnapshotRenderContext {
    SnapshotRenderContext(
      path: path + [component],
      formatting: formatting,
      options: options
    )
  }
}
