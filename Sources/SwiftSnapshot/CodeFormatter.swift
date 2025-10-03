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

    return formatted
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
    var leadingTrivia: Trivia = []
    if let header = header {
      // Add header comments
      for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
        leadingTrivia += .lineComment("\(line)") + .newlines(1)
      }
      leadingTrivia += .newlines(1)
    }

    // Add context documentation if present
    if let context = context {
      for line in context.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
          leadingTrivia += .docLineComment("///") + .newlines(1)
        } else {
          leadingTrivia += .docLineComment("/// \(trimmed)") + .newlines(1)
        }
      }
    }

    // Create import declaration
    let importDecl = ImportDeclSyntax(
      leadingTrivia: leadingTrivia,
      path: [ImportPathComponentSyntax(name: .identifier("Foundation"))]
    )
    statements.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(importDecl))))

    // Create the static variable declaration
    let variableDecl = VariableDeclSyntax(
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
        return try SwiftFormat.Configuration()

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
}
