// Macro definitions for SwiftSnapshot
// These are the public-facing macro attributes that users can apply to their types

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
  #externalMacro(module: "SwiftSnapshotMacrosPlugin", type: "SwiftSnapshotMacro")

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
  #externalMacro(module: "SwiftSnapshotMacrosPlugin", type: "SnapshotIgnoreMacro")

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
  #externalMacro(module: "SwiftSnapshotMacrosPlugin", type: "SnapshotRenameMacro")

/// Redacts a property value in the generated snapshot.
///
/// Two redaction modes are available (mutually exclusive):
/// - `mask`: Replace value with a literal string (default: "•••")
/// - `hash`: Replace with a deterministic hash of the value
///
/// - Parameters:
///   - mask: String literal to use instead of the actual value
///   - hash: If true, use a hash of the value
///
/// Example:
/// ```swift
/// @SwiftSnapshot
/// struct User {
///   @SnapshotRedact(mask: "SECRET")
///   let apiKey: String
///
///   @SnapshotRedact(hash: true)
///   let password: String
/// }
/// ```
@attached(peer)
public macro SnapshotRedact(mask: String? = nil, hash: Bool = false) =
  #externalMacro(module: "SwiftSnapshotMacrosPlugin", type: "SnapshotRedactMacro")

/// Protocol that marks types as exportable via macro-generated methods.
/// This is automatically conformed to by types annotated with @SwiftSnapshot.
public protocol SwiftSnapshotExportable {}
