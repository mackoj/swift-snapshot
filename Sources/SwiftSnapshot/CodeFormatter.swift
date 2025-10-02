import Foundation
import SwiftSyntax

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
