import Foundation
import SwiftSyntax
import SwiftParser
import SwiftFormat

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
        var lines: [String] = []
        
        // Add header if present
        if let header = header {
            lines.append(header)
            if !header.hasSuffix("\n") {
                lines.append("")
            }
        }
        
        // Add context documentation if present
        if let context = context {
            let contextLines = formatContext(context)
            lines.append(contentsOf: contextLines)
        }
        
        // Add import
        lines.append("import Foundation")
        lines.append("")
        
        // Add extension with static variable
        lines.append("extension \(typeName) {")
        
        // Format the expression - try to make it multi-line if it's complex
        let exprString = "\(expression)"
        let formattedExpr = formatExpression(exprString, typeName: typeName, profile: profile)
        
        lines.append("\(profile.indent(level: 1))static let \(variableName): \(typeName) = \(formattedExpr)")
        lines.append("}")
        
        // Join lines
        var result = lines.joined(separator: profile.endOfLine.string)
        
        // TODO: Optionally apply swift-format if enabled via configuration
        // For now, keep the existing formatting to maintain test compatibility
        // result = applySwiftFormat(to: result, profile: profile)
        
        // Trim trailing whitespace if requested
        if profile.trimTrailingWhitespace {
            result = result.split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: profile.endOfLine.string)
        }
        
        // Add final newline if requested
        if profile.insertFinalNewline && !result.hasSuffix("\n") {
            result += profile.endOfLine.string
        }
        
        return result
    }
    
    /// Apply swift-format to code
    private static func applySwiftFormat(to code: String, profile: FormatProfile) -> String {
        // Create swift-format configuration
        var configuration = SwiftFormat.Configuration()
        configuration.indentation = .spaces(profile.indentSize)
        configuration.lineLength = 120
        configuration.maximumBlankLines = 1
        
        do {
            // Parse the code into a syntax tree using SwiftParser
            let sourceFile = Parser.parse(source: code)
            
            // Format the syntax tree
            let formatter = SwiftFormat.SwiftFormatter(configuration: configuration)
            var formattedCode = ""
            
            // Use infinite selection to format the entire file
            let selection = SwiftFormat.Selection.infinite
            
            try formatter.format(
                syntax: sourceFile,
                source: code,
                operatorTable: .standardOperators,
                assumingFileURL: nil,
                selection: selection,
                to: &formattedCode
            )
            
            return formattedCode
        } catch {
            // If formatting fails, return original code
            return code
        }
    }
    
    /// Format context as documentation comments
    private static func formatContext(_ context: String) -> [String] {
        let lines = context.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return "///"
            } else {
                return "/// \(trimmed)"
            }
        }
    }
    
    /// Format an expression with appropriate line breaks and indentation
    private static func formatExpression(_ expr: String, typeName: String, profile: FormatProfile) -> String {
        // If the expression is short, keep it on one line
        if expr.count < 80 && !expr.contains("\n") {
            return expr
        }
        
        // Try to format multi-line initializers nicely
        if expr.contains("(") && expr.contains(")") {
            return formatInitializerExpression(expr, typeName: typeName, profile: profile)
        }
        
        return expr
    }
    
    /// Format initializer expressions with arguments on separate lines
    private static func formatInitializerExpression(_ expr: String, typeName: String, profile: FormatProfile) -> String {
        // Parse basic structure: TypeName(arg1: val1, arg2: val2)
        // This is a simple heuristic - for complex cases we'd need full parsing
        
        // Check if it looks like an initializer
        guard expr.contains("(") && expr.contains(")") else {
            return expr
        }
        
        // For now, return as-is
        // In a production implementation, we'd use SwiftSyntax to properly parse and format
        return expr
    }
}
