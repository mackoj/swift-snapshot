import Foundation

/// Protocol that marks types as exportable via macro-generated methods.
///
/// Types conforming to this protocol have been annotated with the `@SwiftSnapshot` macro,
/// which generates metadata and helper methods for snapshot export.
///
/// ## Macro-Generated Methods
///
/// The `@SwiftSnapshot` macro generates:
/// - `__swiftSnapshot_makeExpr(from:)`: Renders the type with proper redactions applied
/// - `__swiftSnapshot_properties`: Metadata about properties (names, redactions, etc.)
/// - `exportSnapshot()`: Convenience method for exporting instances
///
/// ## Rendering Integration
///
/// When ``RenderOptions/useMacroGeneratedExpressions`` is enabled, ``ValueRenderer``
/// may use `__swiftSnapshot_makeExpr(from:)` for expression-string rendering.
///
/// For stable/default rendering, `__swiftSnapshot_reflectionFields()` is used only for
/// top-level values when field extraction is available. Nested values continue to render
/// through standard reflection/built-ins.
///
/// ## Example
///
/// ```swift
/// @SwiftSnapshot
/// struct User {
///   let id: Int
///   @SnapshotRedact(.mask("***"))
///   let apiKey: String
/// }
/// // User now conforms to SwiftSnapshotExportable
/// ```
///
/// This is automatically conformed to by types annotated with @SwiftSnapshot.
///
/// - Warning: This protocol's expression-string rendering path is experimental and is
///   disabled by default. Prefer the stable built-in/reflection rendering path or
///   custom renderers via ``SnapshotRendererRegistry``.
@available(*, deprecated, message: "Macro-generated expression string rendering is experimental. Prefer reflection/built-ins or SnapshotRendererRegistry custom renderers.")
public protocol SwiftSnapshotExportable {
  /// Generate a Swift expression string for this instance, applying any redactions.
  ///
  /// This method is implemented by the @SwiftSnapshot macro and returns a string
  /// representation of the Swift initializer expression with appropriate redactions
  /// and transformations applied.
  ///
  /// - Parameter instance: The instance to render
  /// - Returns: A Swift expression string (e.g., "User(id: 42, apiKey: \"***\")")
  static func __swiftSnapshot_makeExpr(from instance: Self) -> String

  /// Provides target-level field extraction for stable reflection-based rendering.
  ///
  /// The macro can apply attribute-driven transforms (for example, redaction) while
  /// keeping runtime rendering on the reflection/built-ins path.
  /// The returned fields must be deterministic and ordered by declaration order.
  ///
  /// - Returns: Ordered fields used for top-level reflection rendering.
  func __swiftSnapshot_reflectionFields() -> [SwiftSnapshotReflectionField]
}

/// A single extracted field for reflection-based rendering.
public struct SwiftSnapshotReflectionField {
  public let label: String
  public let value: Any

  public init(label: String, value: Any) {
    self.label = label
    self.value = value
  }
}
