import Foundation

/// Errors that can occur during SwiftSnapshot operations
///
/// `SwiftSnapshotError` provides detailed error information for failures during
/// snapshot generation, file operations, and code rendering. All errors include
/// contextual information to aid debugging.
///
/// ## Error Categories
///
/// - **Type Errors**: ``unsupportedType(_:path:)`` when a type cannot be rendered
/// - **I/O Errors**: ``io(_:)`` for file system operations
/// - **Policy Errors**: ``overwriteDisallowed(_:)`` when file protection is enabled
/// - **Formatting Errors**: ``formatting(_:)`` for code formatting failures
/// - **Reflection Errors**: ``reflection(_:path:)`` for runtime type inspection issues
///
/// ## Example
///
/// ```swift
/// do {
///     try SwiftSnapshotRuntime.export(
///         instance: myValue,
///         variableName: "test",
///         allowOverwrite: false
///     )
/// } catch SwiftSnapshotError.overwriteDisallowed(let url) {
///     print("Cannot overwrite file at: \(url.path)")
/// } catch SwiftSnapshotError.unsupportedType(let type, let path) {
///     print("Cannot render type \(type) at path: \(path.joined(separator: " → "))")
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
public enum SwiftSnapshotError: Error, CustomStringConvertible {
  /// The type cannot be rendered to Swift code
  ///
  /// Thrown when ``ValueRenderer`` encounters a type that cannot be converted to Swift source code.
  /// This occurs when:
  /// - No custom renderer is registered for the type
  /// - The type cannot be handled by built-in renderers
  /// - The type's structure is incompatible with Swift syntax
  ///
  /// - Parameters:
  ///   - String: The name of the unsupported type
  ///   - path: Array of property names showing where in the object graph the error occurred
  ///
  /// **Note**: Register custom renderers using ``SnapshotRendererRegistry`` to handle custom types
  case unsupportedType(String, path: [String])

  /// An I/O error occurred during file operations
  ///
  /// Thrown when file system operations fail, such as:
  /// - Creating output directories
  /// - Writing snapshot files
  /// - Reading configuration files
  ///
  /// - Parameter String: Detailed error message describing the failure
  case io(String)

  /// Overwriting the file is disallowed by policy
  ///
  /// Thrown when attempting to overwrite an existing file and `allowOverwrite` is `false`.
  /// This protects against accidentally modifying existing fixtures.
  ///
  /// - Parameter URL: Path to the file that cannot be overwritten
  case overwriteDisallowed(URL)

  /// A formatting error occurred during code generation
  ///
  /// Thrown when ``CodeFormatter`` fails to format generated Swift code.
  /// This typically indicates issues with:
  /// - SwiftSyntax tree construction
  /// - swift-format integration
  /// - Post-processing transformations
  ///
  /// - Parameter String: Detailed error message describing the formatting failure
  case formatting(String)

  /// A reflection error occurred during type inspection
  ///
  /// Thrown when Swift's runtime reflection (Mirror API) cannot properly inspect a type.
  /// Common causes include:
  /// - Complex generic types with unresolvable structure
  /// - Opaque types or existentials
  /// - Types with unavailable properties
  ///
  /// - Parameters:
  ///   - String: Error message describing the reflection failure
  ///   - path: Array of property names showing where in the object graph the error occurred
  case reflection(String, path: [String])

  public var description: String {
    switch self {
    case .unsupportedType(let typeName, let path):
      let pathStr = path.isEmpty ? "" : " at path: \(path.joined(separator: " → "))"
      return "Unsupported type: \(typeName)\(pathStr)"

    case .io(let message):
      return "I/O error: \(message)"

    case .overwriteDisallowed(let url):
      return "Overwrite disallowed for file: \(url.path)"

    case .formatting(let message):
      return "Formatting error: \(message)"

    case .reflection(let message, let path):
      let pathStr = path.isEmpty ? "" : " at path: \(path.joined(separator: " → "))"
      return "Reflection error: \(message)\(pathStr)"
    }
  }
}
