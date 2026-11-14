import SwiftLiteralReflection
import Foundation
import IssueReporting
import SwiftFormat
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftBasicFormat
import SwiftOperators

/// Formats Swift code according to a FormatProfile
///
/// `CodeFormatter` handles the complete formatting pipeline for generated snapshot files:
/// 1. **Syntax Tree Construction**: Builds a complete `SourceFileSyntax` with all components
/// 2. **swift-format Integration**: Applies swift-format rules for code formatting
/// 3. **Post-Processing**: Handles EditorConfig properties not supported by swift-format
///
/// ## Formatting Pipeline
///
/// The formatter processes code in these stages:
///
/// 1. **Build**: Constructs SwiftSyntax tree with header, imports, documentation, and extension
/// 2. **Format**: Applies swift-format for indentation, spacing, and code structure
/// 3. **Post-Process**: Handles line endings, trailing whitespace, and final newline
///
/// ## File Structure
///
/// Generated files follow this structure:
/// ```swift
/// // Header comment (if provided)
///
/// import Foundation
///
/// /// Documentation comment (if provided)
/// extension TypeName {
///     static let variableName: TypeName = ...
/// }
/// ```
///
/// ## EditorConfig Support
///
/// The formatter handles these EditorConfig properties:
/// - `indent_style`: Via swift-format
/// - `indent_size`: Via swift-format  
/// - `end_of_line`: Post-processing (LF or CRLF)
/// - `insert_final_newline`: Post-processing
/// - `trim_trailing_whitespace`: Post-processing
///
/// ## See Also
/// - ``FormatProfile`` for formatting configuration
/// - `FormatConfigLoader` for loading .editorconfig files
/// - ``Literal/generateSwiftCode(instance:variableName:header:context:)``
enum CodeFormatter {
  /// Format a complete Swift file with header, context, and extension
  ///
  /// Constructs and formats a complete Swift source file containing an extension
  /// with a static property.
  ///
  /// ## Process
  ///
  /// 1. Builds SwiftSyntax tree with all components
  /// 2. Converts to string and applies swift-format
  /// 3. Post-processes for EditorConfig properties
  ///
  /// - Parameters:
  ///   - typeName: Name of the type being extended
  ///   - variableName: Name of the static property
  ///   - expression: SwiftSyntax expression for the property value
  ///   - header: Optional header comment (appears at top of file)
  ///   - context: Optional documentation comment (appears above property)
  ///   - profile: Formatting profile with style rules
  ///   - configSource: The format config the profile came from. A `.swift-format` file is
  ///     applied whole, not just the parts a profile holds.
  ///
  /// - Returns: Fully formatted Swift source code as a string
  static func formatFile(
    typeName: String,
    variableName: String,
    expression: ExprSyntax,
    header: String?,
    context: String?,
    profile: FormatProfile,
    configSource: FormatConfigSource? = nil,
    additionalImports: [String] = []
  ) -> String {
    // Build the complete syntax tree
    let sourceFile = buildSourceFile(
      typeName: typeName,
      variableName: variableName,
      expression: expression,
      header: header,
      context: context,
      additionalImports: additionalImports
    )

    // Apply SwiftFormat
    let formatted = applySwiftFormat(
      sourceFile: sourceFile, profile: profile, configSource: configSource)

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
    context: String?,
    additionalImports: [String]
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

    // A fixture that mentions a type from another module needs that module imported, and
    // the renderer has no way to know which one that is. Sorted, so the output stays
    // deterministic whatever order they were given in.
    for module in Set(additionalImports).sorted() {
      let decl = ImportDeclSyntax(
        path: [ImportPathComponentSyntax(name: .identifier(module))]
      )
      statements.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(decl))))
    }

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
  ///
  /// swift-format prints `sourceFile` itself. `source` only feeds its location converter, so
  /// it is the tree's own text: that is what the converter's offsets index into. It used to be
  /// a `BasicFormat` pass over the tree, which cost more than a quarter of a render and gave
  /// locations for a different text.
  private static func applySwiftFormat(
    sourceFile: SourceFileSyntax,
    profile: FormatProfile,
    configSource: FormatConfigSource?
  ) -> String {
    do {
      // Load configuration from file or use defaults
      let configuration = try loadSwiftFormatConfiguration(
        profile: profile, configSource: configSource)

      // Format the syntax tree
      let formatter = SwiftFormat.SwiftFormatter(configuration: configuration)
      var formattedCode = ""

      // swift-format expects operators already folded, and stops the process when they are
      // not: a range in a fixture renders as `0...3`, and `Literal.source` crashed on it.
      let folded = try OperatorTable.standardOperators.foldAll(sourceFile)
      let foldedFile = folded.as(SourceFileSyntax.self) ?? sourceFile

      try formatter.format(
        syntax: foldedFile,
        source: foldedFile.description,
        operatorTable: .standardOperators,
        assumingFileURL: nil,
        selection: SwiftFormat.Selection.infinite,
        to: &formattedCode
      )

      return formattedCode
    } catch {
      // If formatting fails, return original code
      reportIssue("Failed to format code: \(error.localizedDescription)")
      return sourceFile.formatted().description
    }
  }

  /// Load SwiftFormat configuration from file or create from profile.
  ///
  /// The source comes from the caller, which read it from the `literalConfiguration`
  /// dependency. Reading `LiteralConfig` here instead ignored a test's scoped source.
  /// An `.editorconfig` source needs no second read: `profile` was loaded from it.
  private static func loadSwiftFormatConfiguration(
    profile: FormatProfile,
    configSource: FormatConfigSource?
  ) throws -> SwiftFormat.Configuration {
    if case .swiftFormat(let url) = configSource {
      if FileManager.default.fileExists(atPath: url.path) {
        return try SwiftFormat.Configuration(contentsOf: url)
      }
      return SwiftFormat.Configuration()
    }
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

    configuration.indentSwitchCaseLabels = true
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    configuration.lineBreakBeforeEachArgument = true
    configuration.tabWidth = 2

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

  /// Trim trailing spaces and tabs from each line.
  ///
  /// By hand rather than with a regular expression per line, which was most of the
  /// post-processing time.
  private static func trimTrailingWhitespace(_ code: String) -> String {
    var result = ""
    result.reserveCapacity(code.utf8.count)
    for (index, line) in code.utf8.split(
      separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false
    ).enumerated() {
      if index > 0 { result += "\n" }
      var end = line.endIndex
      while end > line.startIndex {
        let byte = line[line.index(before: end)]
        guard byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") else { break }
        end = line.index(before: end)
      }
      result += String(Substring(code.utf8[line.startIndex..<end]))
    }
    return result
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
