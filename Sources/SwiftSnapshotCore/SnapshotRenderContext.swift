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
  public let path: [String]

  /// Formatting profile to use
  public let formatting: FormatProfile

  /// Render options
  public let options: RenderOptions

  /// Object identities already visited on this rendering path.
  ///
  /// Used by ``ValueRenderer`` to detect circular references in class hierarchies.
  /// Structs are value types and cannot form cycles; only class instances are tracked.
  let visitedObjectIDs: Set<ObjectIdentifier>

  /// Creates a render context with specified configuration
  public init(
    path: [String] = [],
    formatting: FormatProfile? = nil,
    options: RenderOptions? = nil
  ) {
    @Dependency(\.swiftSnapshotConfig) var snapshotConfig
    self.path = path
    self.formatting = formatting ?? snapshotConfig.getFormatProfile()
    self.options = options ?? snapshotConfig.getRenderOptions()
    self.visitedObjectIDs = []
  }

  /// Internal memberwise init used when constructing child contexts.
  init(
    path: [String],
    formatting: FormatProfile,
    options: RenderOptions,
    visitedObjectIDs: Set<ObjectIdentifier>
  ) {
    self.path = path
    self.formatting = formatting
    self.options = options
    self.visitedObjectIDs = visitedObjectIDs
  }

  /// Create a new context with an additional path component
  func appending(path component: String) -> SnapshotRenderContext {
    SnapshotRenderContext(
      path: path + [component],
      formatting: formatting,
      options: options,
      visitedObjectIDs: visitedObjectIDs
    )
  }

  /// Create a new context that records a visited class object identity.
  func addingVisitedID(_ id: ObjectIdentifier) -> SnapshotRenderContext {
    var newIDs = visitedObjectIDs
    newIDs.insert(id)
    return SnapshotRenderContext(
      path: path,
      formatting: formatting,
      options: options,
      visitedObjectIDs: newIDs
    )
  }
}
