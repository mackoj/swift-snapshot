import Foundation
import IssueReporting
import SwiftFormat
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Formats Swift code according to a FormatProfile
enum CodeFormatter {
  /// Format a complete Swift file with header, context, and extension
  static func formatFile(
    typeName: String,
    variableName: String,
    expression: ExprSyntax,
    header: String?,
    context: String?,
    profile: FormatProfile
  ) -> String {
    // Build the complete syntax tree
    let sourceFile = buildSourceFile(
      typeName: typeName,
      variableName: variableName,
      expression: expression,
      header: header,
      context: context
    )

    // Convert to string for formatting
    let sourceCode = sourceFile.formatted().description

    // Apply SwiftFormat
    let formatted = applySwiftFormat(to: sourceCode, sourceFile: sourceFile, profile: profile)

    // Apply post-processing for EditorConfig properties not handled by swift-format
    let postProcessed = applyEditorConfigPostProcessing(formatted, profile: profile)

    return postProcessed
  }

  /// Build a complete SourceFileSyntax tree
  private static func buildSourceFile(
    typeName: String,
    variableName: String,
    expression: ExprSyntax,
    header: String?,
    context: String?
  ) -> SourceFileSyntax {
    var statements: [CodeBlockItemSyntax] = []

    // Add header as leading trivia if present
    var importLeadingTrivia: Trivia = []
    if let header = header {
      // Add header comments
      for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
        importLeadingTrivia += .lineComment("\(line)") + .newlines(1)
      }
      importLeadingTrivia += .newlines(1)
    }

    // Create import declaration (header goes here, but NOT context)
    let importDecl = ImportDeclSyntax(
      leadingTrivia: importLeadingTrivia,
      path: [ImportPathComponentSyntax(name: .identifier("Foundation"))]
    )
    statements.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(importDecl))))

    // Build context documentation as leading trivia for the variable declaration
    var variableLeadingTrivia: Trivia = []
    if let context = context {
      for line in context.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
          variableLeadingTrivia += .docLineComment("///") + .newlines(1)
        } else {
          variableLeadingTrivia += .docLineComment("/// \(trimmed)") + .newlines(1)
        }
      }
    }

    // Create the static variable declaration with context as leading trivia
    let variableDecl = VariableDeclSyntax(
      leadingTrivia: variableLeadingTrivia,
      modifiers: [DeclModifierSyntax(name: .keyword(.static))],
      bindingSpecifier: .keyword(.let),
      bindings: PatternBindingListSyntax([
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier(variableName)),
          typeAnnotation: TypeAnnotationSyntax(
            type: IdentifierTypeSyntax(name: .identifier(typeName))
          ),
          initializer: InitializerClauseSyntax(value: expression)
        )
      ])
    )

    // Create extension declaration
    let extensionDecl = ExtensionDeclSyntax(
      extendedType: IdentifierTypeSyntax(name: .identifier(typeName)),
      memberBlock: MemberBlockSyntax(
        members: MemberBlockItemListSyntax([
          MemberBlockItemSyntax(decl: variableDecl)
        ])
      )
    )
    statements.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(extensionDecl))))

    return SourceFileSyntax(statements: CodeBlockItemListSyntax(statements))
  }

  /// Apply swift-format to code
  private static func applySwiftFormat(
    to code: String,
    sourceFile: SourceFileSyntax,
    profile: FormatProfile
  ) -> String {
    do {
      // Load configuration from file or use defaults
      let configuration = try loadSwiftFormatConfiguration(profile: profile)

      // Format the syntax tree
      let formatter = SwiftFormat.SwiftFormatter(configuration: configuration)
      var formattedCode = ""

      try formatter.format(
        syntax: sourceFile,
        source: code,
        operatorTable: .standardOperators,
        assumingFileURL: nil,
        selection: SwiftFormat.Selection.infinite,
        to: &formattedCode
      )

      return formattedCode
    } catch {
      // If formatting fails, return original code
      reportIssue("Failed to format code: \(error.localizedDescription)")
      return code
    }
  }

  /// Load SwiftFormat configuration from file or create from profile
  private static func loadSwiftFormatConfiguration(profile: FormatProfile) throws
    -> SwiftFormat.Configuration
  {
    // Check if a format config source is configured
    if let configSource = SwiftSnapshotConfig.getFormatConfigSource() {
      switch configSource {
      case .swiftFormat(let url):
        // Load directly from .swift-format file
        if FileManager.default.fileExists(atPath: url.path) {
          return try SwiftFormat.Configuration(contentsOf: url)
        }
        return SwiftFormat.Configuration()

      case .editorconfig:
        // Load from .editorconfig and convert to SwiftFormat.Configuration
        let formatProfile = try FormatConfigLoader.loadProfile(from: configSource)
        return configurationFromProfile(formatProfile)
      }
    }

    // No config file specified, use the profile settings
    return configurationFromProfile(profile)
  }

  /// Convert FormatProfile to SwiftFormat.Configuration
  private static func configurationFromProfile(_ profile: FormatProfile)
    -> SwiftFormat.Configuration
  {
    var configuration = SwiftFormat.Configuration()

    // Set indentation
    switch profile.indentStyle {
    case .space:
      configuration.indentation = .spaces(profile.indentSize)
    case .tab:
      configuration.indentation = .tabs(profile.indentSize)
    }

    // Set line length (reasonable default)
    configuration.lineLength = 100

    // Set maximum blank lines
    configuration.maximumBlankLines = 1

    return configuration
  }

  /// Apply EditorConfig post-processing for properties not handled by swift-format.
  ///
  /// This function handles:
  /// - `trim_trailing_whitespace`: Removes trailing whitespace from each line
  /// - `end_of_line`: Converts line endings (LF or CRLF)
  /// - `insert_final_newline`: Ensures file ends with a newline (or not)
  ///
  /// - Parameters:
  ///   - code: The formatted code from swift-format
  ///   - profile: The formatting profile with EditorConfig settings
  /// - Returns: Post-processed code with EditorConfig properties applied
  private static func applyEditorConfigPostProcessing(
    _ code: String,
    profile: FormatProfile
  ) -> String {
    var result = code

    // 1. First normalize all line endings to LF for consistent processing
    result = result.replacingOccurrences(of: "\r\n", with: "\n")
    result = result.replacingOccurrences(of: "\r", with: "\n")

    // 2. Trim trailing whitespace
    if profile.trimTrailingWhitespace {
      result = trimTrailingWhitespace(result)
    }

    // 3. Handle final newline (using LF temporarily)
    result = applyFinalNewline(result, insert: profile.insertFinalNewline, lineEnding: "\n")

    // 4. Convert to desired line ending style
    if profile.endOfLine == .crlf {
      result = result.replacingOccurrences(of: "\n", with: "\r\n")
    }

    return result
  }

  /// Trim trailing whitespace from each line
  private static func trimTrailingWhitespace(_ code: String) -> String {
    let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
    let trimmedLines = lines.map { line -> String in
      let lineStr = String(line)
      // Trim trailing spaces and tabs, but preserve the line itself
      return lineStr.replacingOccurrences(
        of: "[ \\t]+$",
        with: "",
        options: .regularExpression
      )
    }
    return trimmedLines.joined(separator: "\n")
  }

  /// Apply or remove final newline based on configuration
  private static func applyFinalNewline(
    _ code: String,
    insert: Bool,
    lineEnding: String
  ) -> String {
    if insert {
      // Ensure file ends with exactly one newline
      if code.isEmpty {
        return lineEnding
      }
      // Remove any trailing newlines first
      var result = code
      while result.hasSuffix(lineEnding) {
        result = String(result.dropLast(lineEnding.count))
      }
      // Add exactly one newline
      return result + lineEnding
    } else {
      // Remove all trailing newlines
      var result = code
      while result.hasSuffix(lineEnding) {
        result = String(result.dropLast(lineEnding.count))
      }
      return result
    }
  }
}
