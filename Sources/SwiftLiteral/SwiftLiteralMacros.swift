import SwiftLiteralCore
// Macro definitions for SwiftLiteral
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
/// - A convenience `writeLiteral` method
///
/// - Parameters:
///   - folder: Optional output directory hint (literal string)
///
/// Example:
/// ```swift
/// @SwiftLiteral(folder: "Fixtures/Users")
/// struct User {
///   let id: String
///   let name: String
/// }
/// ```
@attached(
  member, names: named(__swiftLiteral_folder), named(__swiftLiteral_properties),
  named(__swiftLiteral_fields), named(writeLiteral), named(__SwiftLiteral_PropertyMetadata),
  named(__SwiftLiteral_Redaction))
@attached(extension, conformances: LiteralFields, names: named(writeLiteral))
public macro SwiftLiteral(folder: String? = nil) =
  #externalMacro(module: "SwiftLiteralMacros", type: "SwiftLiteralMacro")

/// Excludes a property from snapshot generation.
///
/// Properties marked with this attribute will not appear in the generated
/// initializer expression or metadata array.
///
/// Example:
/// ```swift
/// @SwiftLiteral
/// struct User {
///   let id: String
///   @LiteralIgnore
///   let transientCache: [String: Any]
/// }
/// ```
@attached(peer)
public macro LiteralIgnore() =
  #externalMacro(module: "SwiftLiteralMacros", type: "LiteralIgnoreMacro")

/// Renames a property in the generated initializer expression.
///
/// The property will be emitted with the specified label instead of its
/// declared name.
///
/// - Parameter name: The new name to use in the initializer
///
/// Example:
/// ```swift
/// @SwiftLiteral
/// struct User {
///   @LiteralRename("displayName")
///   let name: String
/// }
/// // Generated: User(displayName: "...")
/// ```
@attached(peer)
public macro LiteralRename(_ name: String) =
  #externalMacro(module: "SwiftLiteralMacros", type: "LiteralRenameMacro")

/// Redacts a property value in the generated snapshot.
///
/// - Parameter style: The redaction style to apply (`.mask(String)` or `.hash`)
///
/// Example:
/// ```swift
/// @SwiftLiteral
/// struct User {
///   @LiteralRedact(.mask("SECRET"))
///   let apiKey: String
///
///   @LiteralRedact(.hash)
///   let password: String
/// }
/// ```
@attached(peer)
public macro LiteralRedact(_ style: RedactionStyle = .mask("•••")) =
  #externalMacro(module: "SwiftLiteralMacros", type: "LiteralRedactMacro")

// LiteralFields protocol is now defined in SwiftLiteralCore
// and re-exported here for backwards compatibility
