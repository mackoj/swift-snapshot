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
/// When ``ValueRenderer`` encounters a type conforming to this protocol during
/// nested rendering, it will use the `__swiftSnapshot_makeExpr` method to ensure
/// redactions and other macro-generated configurations are properly applied.
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
}
