import Foundation

/// Errors that can occur during SwiftSnapshot operations
public enum SwiftSnapshotError: Error, CustomStringConvertible {
  /// The type cannot be rendered to Swift code
  case unsupportedType(String, path: [String])

  /// An I/O error occurred
  case io(String)

  /// Overwriting the file is disallowed
  case overwriteDisallowed(URL)

  /// A formatting error occurred
  case formatting(String)

  /// A reflection error occurred
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
