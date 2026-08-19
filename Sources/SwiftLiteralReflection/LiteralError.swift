import Foundation

/// Everything that can go wrong, in one type.
///
/// The library never guesses. If a value cannot be turned into source that compiles,
/// it throws. It does not substitute `nil` and hand you a file that looks fine and
/// does not build.
public enum LiteralError: Error, CustomStringConvertible, Equatable {
  /// No renderer knows this type, and reflection cannot reach its contents.
  case unsupportedType(String, path: [String])

  /// Reflection reached the value but could not turn it into an initializer call.
  case reflection(String, path: [String])

  /// Reading or writing a file failed.
  case io(String)

  /// The target file exists and `allowOverwrite` was false.
  case overwriteDisallowed(URL)

  /// swift-format rejected the generated source.
  case formatting(String)

  public var description: String {
    switch self {
    case .unsupportedType(let typeName, let path):
      return "Cannot render '\(typeName)'\(Self.at(path)). "
        + "Register a custom renderer with LiteralConfig.registerRenderer(\(typeName).self)."
    case .reflection(let message, let path):
      return "\(message)\(Self.at(path))"
    case .io(let message):
      return message
    case .overwriteDisallowed(let url):
      return "File exists and overwrite is disallowed: \(url.path)"
    case .formatting(let message):
      return "Formatting failed: \(message)"
    }
  }

  private static func at(_ path: [String]) -> String {
    path.isEmpty ? "" : " at \(path.joined(separator: "."))"
  }
}
