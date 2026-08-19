/// How the generated file should look.
///
/// These are the settings an `.editorconfig` carries: indentation, line endings,
/// trailing whitespace. Point the library at your project's config and the fixtures
/// come out looking like the rest of your code, so the diff is about the data.
///
/// See ``FormatConfigLoader`` for reading this off a file.
public struct FormatProfile: Sendable, Equatable {
  /// Spaces or tabs.
  public var indentStyle: IndentStyle

  /// Spaces per indent level. Ignored when ``indentStyle`` is `.tab`.
  public var indentSize: Int

  /// Line endings.
  public var endOfLine: EndOfLine

  /// End the file with a newline.
  public var insertFinalNewline: Bool

  /// Strip spaces and tabs at end of line.
  public var trimTrailingWhitespace: Bool

  public enum IndentStyle: Sendable {
    case space
    case tab
  }

  public enum EndOfLine: Sendable {
    /// `\n`
    case lf
    /// `\r\n`
    case crlf

    var string: String {
      switch self {
      case .lf: "\n"
      case .crlf: "\r\n"
      }
    }
  }

  public init(
    indentStyle: IndentStyle = .space,
    indentSize: Int = 4,
    endOfLine: EndOfLine = .lf,
    insertFinalNewline: Bool = true,
    trimTrailingWhitespace: Bool = true
  ) {
    self.indentStyle = indentStyle
    self.indentSize = indentSize
    self.endOfLine = endOfLine
    self.insertFinalNewline = insertFinalNewline
    self.trimTrailingWhitespace = trimTrailingWhitespace
  }

  /// The library defaults: four spaces, LF, final newline, no trailing whitespace.
  public static let `default` = FormatProfile()

  func indent(level: Int) -> String {
    switch indentStyle {
    case .space: String(repeating: " ", count: indentSize * level)
    case .tab: String(repeating: "\t", count: level)
    }
  }
}
