import SwiftSnapshotCore
// Macro definitions for SwiftSnapshot
// These are the public-facing macro attributes that users can apply to their types

/// Defines how a property value should be redacted in snapshots.
public enum RedactionStyle {
  /// Replace the value with a custom string literal.
  case mask(String)
  /// Replace the value with a deterministic hash.
  case hash
}

/// Marks a type for snapshot fixture export with compile-time metadata generation.
///
/// This macro generates:
/// - Property metadata for deterministic ordering and configuration
/// - Optimized expression builders that bypass reflection
/// - A convenience `exportSnapshot` method
///
/// - Parameters:
///   - folder: Optional output directory hint (literal string)
///
/// Example:
/// ```swift
/// @SwiftSnapshot(folder: "Fixtures/Users")
/// struct User {
///   let id: String
///   let name: String
/// }
/// ```
@attached(
  member, names: named(__swiftSnapshot_folder), named(__swiftSnapshot_properties),
  named(__swiftSnapshot_makeExpr), named(exportSnapshot), named(__SwiftSnapshot_PropertyMetadata),
  named(__SwiftSnapshot_Redaction))
@attached(extension, conformances: SwiftSnapshotExportable, names: named(exportSnapshot))
public macro SwiftSnapshot(folder: String? = nil) =
  #externalMacro(module: "SwiftSnapshotMacros", type: "SwiftSnapshotMacro")

/// Excludes a property from snapshot generation.
///
/// Properties marked with this attribute will not appear in the generated
/// initializer expression or metadata array.
///
/// Example:
/// ```swift
/// @SwiftSnapshot
/// struct User {
///   let id: String
///   @SnapshotIgnore
///   let transientCache: [String: Any]
/// }
/// ```
@attached(peer)
public macro SnapshotIgnore() =
  #externalMacro(module: "SwiftSnapshotMacros", type: "SnapshotIgnoreMacro")

/// Renames a property in the generated initializer expression.
///
/// The property will be emitted with the specified label instead of its
/// declared name.
///
/// - Parameter name: The new name to use in the initializer
///
/// Example:
/// ```swift
/// @SwiftSnapshot
/// struct User {
///   @SnapshotRename("displayName")
///   let name: String
/// }
/// // Generated: User(displayName: "...")
/// ```
@attached(peer)
public macro SnapshotRename(_ name: String) =
  #externalMacro(module: "SwiftSnapshotMacros", type: "SnapshotRenameMacro")

/// Redacts a property value in the generated snapshot.
///
/// - Parameter style: The redaction style to apply (`.mask(String)` or `.hash`)
///
/// Example:
/// ```swift
/// @SwiftSnapshot
/// struct User {
///   @SnapshotRedact(.mask("SECRET"))
///   let apiKey: String
///
///   @SnapshotRedact(.hash)
///   let password: String
/// }
/// ```
@attached(peer)
public macro SnapshotRedact(_ style: RedactionStyle = .mask("•••")) =
  #externalMacro(module: "SwiftSnapshotMacros", type: "SnapshotRedactMacro")

// SwiftSnapshotExportable protocol is now defined in SwiftSnapshotCore
// and re-exported here for backwards compatibility
