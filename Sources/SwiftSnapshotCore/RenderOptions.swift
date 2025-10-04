import Foundation

/// Options controlling how values are rendered to Swift code
///
/// `RenderOptions` configures the behavior of ``ValueRenderer`` during code generation.
/// These options control determinism, output format, and syntax preferences.
///
/// ## Overview
///
/// Configure rendering behavior globally via ``SwiftSnapshotConfig/setRenderOptions(_:)``
/// or access through the dependency injection API.
///
/// ## Example
///
/// ```swift
/// let options = RenderOptions(
///     sortDictionaryKeys: true,      // Deterministic dictionary output
///     setDeterminism: true,          // Deterministic set ordering
///     dataInlineThreshold: 16,       // Small Data as hex, large as base64
///     forceEnumDotSyntax: true       // Use .case instead of Type.case
/// )
/// SwiftSnapshotConfig.setRenderOptions(options)
/// ```
///
/// ## See Also
/// - ``FormatProfile`` for code formatting options
/// - ``SwiftSnapshotConfig`` for global configuration
public struct RenderOptions: Sendable {
  /// Whether to sort dictionary keys lexicographically
  ///
  /// When `true`, dictionary keys are sorted alphabetically in the generated code.
  /// This ensures deterministic output regardless of hash randomization.
  ///
  /// **Default**: `true`
  ///
  /// ## Example
  ///
  /// ```swift
  /// // With sortDictionaryKeys = true:
  /// ["zebra": 1, "apple": 2, "banana": 3]
  /// // Renders as:
  /// ["apple": 2, "banana": 3, "zebra": 1]
  /// ```
  public var sortDictionaryKeys: Bool

  /// Whether to use deterministic ordering for sets
  ///
  /// When `true`, set elements are sorted by their string representation.
  /// This produces consistent output across runs, essential for version control.
  ///
  /// **Default**: `true`
  ///
  /// ## Example
  ///
  /// ```swift
  /// // With setDeterminism = true:
  /// Set(["swift", "ios", "macos"])
  /// // Always renders in same order:
  /// Set(["ios", "macos", "swift"])
  /// ```
  public var setDeterminism: Bool

  /// Threshold in bytes for inlining Data as hex array vs base64
  ///
  /// - **Below threshold**: Renders as hex byte array: `Data([0x01, 0x02, 0x03])`
  /// - **Above threshold**: Renders as base64: `Data(base64Encoded: "...")!`
  ///
  /// **Default**: `16` bytes
  ///
  /// ## Example
  ///
  /// ```swift
  /// // With dataInlineThreshold = 16:
  /// let small = Data([0x01, 0x02, 0x03])  // 3 bytes
  /// // Renders as: Data([0x01, 0x02, 0x03])
  ///
  /// let large = Data(count: 100)  // 100 bytes
  /// // Renders as: Data(base64Encoded: "AAAA...")!
  /// ```
  public var dataInlineThreshold: Int

  /// Whether to force enum dot syntax when possible
  ///
  /// When `true`, uses `.case` syntax instead of `TypeName.case` for enum values.
  /// This produces more concise and idiomatic Swift code.
  ///
  /// **Default**: `true`
  ///
  /// ## Example
  ///
  /// ```swift
  /// // With forceEnumDotSyntax = true:
  /// let status: Status = .active
  ///
  /// // With forceEnumDotSyntax = false:
  /// let status: Status = Status.active
  /// ```
  public var forceEnumDotSyntax: Bool

  /// Creates render options with specified behavior
  ///
  /// - Parameters:
  ///   - sortDictionaryKeys: Whether to sort dictionary keys (default: `true`)
  ///   - setDeterminism: Whether to use deterministic set ordering (default: `true`)
  ///   - dataInlineThreshold: Byte threshold for Data rendering (default: `16`)
  ///   - forceEnumDotSyntax: Whether to use dot syntax for enums (default: `true`)
  public init(
    sortDictionaryKeys: Bool,
    setDeterminism: Bool,
    dataInlineThreshold: Int,
    forceEnumDotSyntax: Bool
  ) {
    self.sortDictionaryKeys = sortDictionaryKeys
    self.setDeterminism = setDeterminism
    self.dataInlineThreshold = dataInlineThreshold
    self.forceEnumDotSyntax = forceEnumDotSyntax
  }
}

/// Profile controlling code formatting
///
/// `FormatProfile` defines formatting rules applied to generated Swift code.
/// These settings ensure consistent code style across all snapshots.
///
/// ## Overview
///
/// Formatting profiles can be:
/// - Set manually via ``SwiftSnapshotConfig/setFormattingProfile(_:)``
/// - Loaded from `.editorconfig` or `.swift-format` files
/// - Integrated with swift-format for consistent formatting
///
/// ## Example
///
/// ```swift
/// let profile = FormatProfile(
///     indentStyle: .space,
///     indentSize: 2,
///     endOfLine: .lf,
///     insertFinalNewline: true,
///     trimTrailingWhitespace: true
/// )
/// SwiftSnapshotConfig.setFormattingProfile(profile)
/// ```
///
/// ## EditorConfig Integration
///
/// Load formatting from `.editorconfig`:
///
/// ```swift
/// let configURL = URL(fileURLWithPath: ".editorconfig")
/// SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
/// ```
///
/// See ``FormatConfigLoader`` for details on configuration file support.
///
/// ## See Also
/// - ``RenderOptions`` for rendering behavior
/// - ``FormatConfigLoader`` for loading configuration files
/// - ``CodeFormatter`` for the formatting implementation
public struct FormatProfile: Sendable {
  /// Style of indentation
  ///
  /// Determines whether to use spaces or tabs for indentation.
  ///
  /// **Default**: `.space`
  public var indentStyle: IndentStyle

  /// Number of spaces per indent level
  ///
  /// When ``IndentStyle/space`` is used, this specifies how many spaces per indentation level.
  /// Common values are 2 or 4.
  ///
  /// **Default**: `4`
  ///
  /// **Range**: 1-8 (values outside this range may produce unexpected results)
  public var indentSize: Int

  /// Line ending style
  ///
  /// Determines which line ending sequence to use in generated files.
  ///
  /// **Default**: `.lf` (Unix-style line endings)
  public var endOfLine: EndOfLine

  /// Whether to insert a final newline at end of file
  ///
  /// When `true`, ensures generated files end with a newline character.
  /// This is a common convention in Unix/POSIX systems.
  ///
  /// **Default**: `true`
  public var insertFinalNewline: Bool

  /// Whether to trim trailing whitespace on each line
  ///
  /// When `true`, removes spaces and tabs at the end of each line.
  /// This prevents unnecessary whitespace in version control.
  ///
  /// **Default**: `true`
  public var trimTrailingWhitespace: Bool

  /// Style of indentation
  public enum IndentStyle: Sendable {
    /// Use spaces for indentation
    case space
    /// Use tabs for indentation
    case tab
  }

  /// Line ending style
  public enum EndOfLine: Sendable {
    /// Unix-style line endings (\\n)
    case lf
    /// Windows-style line endings (\\r\\n)
    case crlf

    var string: String {
      switch self {
      case .lf: return "\n"
      case .crlf: return "\r\n"
      }
    }
  }

  /// Creates a format profile with specified settings
  ///
  /// - Parameters:
  ///   - indentStyle: Style of indentation (default: `.space`)
  ///   - indentSize: Number of spaces per indent level (default: `4`)
  ///   - endOfLine: Line ending style (default: `.lf`)
  ///   - insertFinalNewline: Whether to add final newline (default: `true`)
  ///   - trimTrailingWhitespace: Whether to trim trailing whitespace (default: `true`)
  public init(
    indentStyle: IndentStyle,
    indentSize: Int,
    endOfLine: EndOfLine,
    insertFinalNewline: Bool,
    trimTrailingWhitespace: Bool
  ) {
    self.indentStyle = indentStyle
    self.indentSize = indentSize
    self.endOfLine = endOfLine
    self.insertFinalNewline = insertFinalNewline
    self.trimTrailingWhitespace = trimTrailingWhitespace
  }

  /// Create an indent string for the given level
  ///
  /// Generates the appropriate indentation string based on ``indentStyle`` and ``indentSize``.
  ///
  /// - Parameter level: The indentation level (0 = no indent, 1 = one level, etc.)
  /// - Returns: String containing the appropriate indentation
  ///
  /// ## Example
  ///
  /// ```swift
  /// let profile = FormatProfile(indentStyle: .space, indentSize: 2, ...)
  /// profile.indent(level: 0)  // ""
  /// profile.indent(level: 1)  // "  " (2 spaces)
  /// profile.indent(level: 2)  // "    " (4 spaces)
  /// ```
  func indent(level: Int) -> String {
    String(repeating: " ", count: indentSize * level)
  }
}
