import Foundation

/// Loads format configuration from .editorconfig or .swift-format files.
///
/// Provides utilities to parse formatting configuration from standard config files
/// and search for them in directory hierarchies.
///
/// Supports:
/// - `.editorconfig` with standard formatting properties
/// - `.swift-format` JSON configuration files
///
/// Example:
/// ```swift
/// // Load from .editorconfig
/// let configURL = URL(fileURLWithPath: ".editorconfig")
/// let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
///
/// // Or search for config file
/// if let found = FormatConfigLoader.findConfigFile(
///     startingFrom: URL(fileURLWithPath: "."),
///     named: ".editorconfig"
/// ) {
///     let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(found))
/// }
/// ```
enum FormatConfigLoader {

  /// Load format profile from configuration source.
  ///
  /// Parses the specified configuration file and returns a `FormatProfile`
  /// with the extracted formatting settings.
  ///
  /// - Parameter source: The format configuration source, or `nil` for defaults
  /// - Returns: A `FormatProfile` configured from the file, or defaults if `nil`
  /// - Throws: `SwiftSnapshotError.formatting` if the file cannot be parsed
  static func loadProfile(from source: FormatConfigSource?) throws -> FormatProfile {
    guard let source = source else {
      return SwiftSnapshotConfig.libraryDefaultFormatProfile()
    }

    switch source {
    case .editorconfig(let url):
      return try loadFromEditorConfig(url)
    case .swiftFormat(let url):
      return try loadFromSwiftFormat(url)
    }
  }

  /// Parse .editorconfig file
  private static func loadFromEditorConfig(_ url: URL) throws -> FormatProfile {
    let contents = try String(contentsOf: url, encoding: .utf8)
    
    // Start with library defaults
    var indentSize = 4
    var indentStyle = FormatProfile.IndentStyle.space
    var endOfLine = FormatProfile.EndOfLine.lf
    var insertFinalNewline = true
    var trimTrailingWhitespace = true

    // Parse .editorconfig format
    // Properties are accumulated across sections, with later sections overriding earlier ones
    let lines = contents.split(separator: "\n")
    var currentlyInSwiftSection = true  // Start as true to process default section
    var hasSeenSection = false

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Skip comments and empty lines
      if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
        continue
      }

      // Check for section headers
      if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
        hasSeenSection = true
        let section = trimmed.dropFirst().dropLast()
        // Check if this section applies to Swift files
        // Sections that apply: [*] or [*.swift] or other patterns matching .swift files
        currentlyInSwiftSection = section == "*" || section.contains("*.swift")
        continue
      }

      // Parse key-value pairs
      // Process if: no section seen yet (default section) OR we're in a Swift-applicable section
      if !hasSeenSection || currentlyInSwiftSection {
        let parts = trimmed.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
          let key = parts[0].trimmingCharacters(in: .whitespaces)
          let value = parts[1].trimmingCharacters(in: .whitespaces)

          switch key {
          case "indent_style":
            if value == "space" {
              indentStyle = .space
            } else if value == "tab" {
              indentStyle = .tab
            }
          case "indent_size":
            if let size = Int(value) {
              indentSize = size
            }
          case "end_of_line":
            switch value {
            case "lf":
              endOfLine = .lf
            case "crlf":
              endOfLine = .crlf
            default:
              break
            }
          case "insert_final_newline":
            insertFinalNewline = (value == "true")
          case "trim_trailing_whitespace":
            trimTrailingWhitespace = (value == "true")
          default:
            break
          }
        }
      }
    }

    return FormatProfile(
      indentStyle: indentStyle,
      indentSize: indentSize,
      endOfLine: endOfLine,
      insertFinalNewline: insertFinalNewline,
      trimTrailingWhitespace: trimTrailingWhitespace
    )
  }

  /// Parse .swift-format file (JSON format)
  private static func loadFromSwiftFormat(_ url: URL) throws -> FormatProfile {
    let data = try Data(contentsOf: url)

    // Parse JSON configuration
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw SwiftSnapshotError.formatting("Invalid .swift-format file format")
    }

    // Extract relevant settings with defaults
    var indentSize = 4
    var indentStyle = FormatProfile.IndentStyle.space
    var endOfLine = FormatProfile.EndOfLine.lf
    var insertFinalNewline = true
    var trimTrailingWhitespace = true

    // Parse indentation
    if let indentation = json["indentation"] as? [String: Any] {
      if let spaces = indentation["spaces"] as? Int {
        indentSize = spaces
        indentStyle = .space
      }
    } else if let indent = json["indent"] as? Int {
      indentSize = indent
    } else if let tabWidth = json["tabWidth"] as? Int {
      indentSize = tabWidth
    }

    // Note: swift-format doesn't provide line ending configuration
    // We use platform defaults (LF on Unix-like systems)

    // Most .swift-format files use LF by default on macOS
    // insertFinalNewline defaults to true
    // trimTrailingWhitespace defaults to true

    return FormatProfile(
      indentStyle: indentStyle,
      indentSize: indentSize,
      endOfLine: endOfLine,
      insertFinalNewline: insertFinalNewline,
      trimTrailingWhitespace: trimTrailingWhitespace
    )
  }

  /// Search for configuration file in directory hierarchy.
  ///
  /// Walks up the directory tree (up to 10 levels) looking for the specified file.
  /// Useful for finding project-level configuration files.
  ///
  /// - Parameters:
  ///   - directory: Starting directory for the search
  ///   - fileName: Name of the configuration file to find
  /// - Returns: URL of the found file, or `nil` if not found
  ///
  /// Example:
  /// ```swift
  /// let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  /// if let config = FormatConfigLoader.findConfigFile(
  ///     startingFrom: projectRoot,
  ///     named: ".editorconfig"
  /// ) {
  ///     print("Found config at: \(config.path)")
  /// }
  /// ```
  static func findConfigFile(startingFrom directory: URL, named fileName: String) -> URL? {
    var currentDir = directory

    // Search up to 10 levels up
    for _ in 0..<10 {
      let configPath = currentDir.appendingPathComponent(fileName)
      if FileManager.default.fileExists(atPath: configPath.path) {
        return configPath
      }

      let parentDir = currentDir.deletingLastPathComponent()
      if parentDir.path == currentDir.path {
        break
      }
      currentDir = parentDir
    }

    return nil
  }
}
