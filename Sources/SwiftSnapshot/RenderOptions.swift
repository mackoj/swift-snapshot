import Foundation

/// Options controlling how values are rendered to Swift code
public struct RenderOptions {
    /// Whether to sort dictionary keys lexicographically
    public var sortDictionaryKeys: Bool
    
    /// Whether to use deterministic ordering for sets
    public var setDeterminism: Bool
    
    /// Threshold in bytes for inlining Data as hex array vs base64
    public var dataInlineThreshold: Int
    
    /// Whether to force enum dot syntax when possible
    public var forceEnumDotSyntax: Bool
    
    public init(
        sortDictionaryKeys: Bool = true,
        setDeterminism: Bool = true,
        dataInlineThreshold: Int = 16,
        forceEnumDotSyntax: Bool = true
    ) {
        self.sortDictionaryKeys = sortDictionaryKeys
        self.setDeterminism = setDeterminism
        self.dataInlineThreshold = dataInlineThreshold
        self.forceEnumDotSyntax = forceEnumDotSyntax
    }
}

/// Profile controlling code formatting
public struct FormatProfile {
    /// Style of indentation (only "space" supported initially)
    public var indentStyle: IndentStyle
    
    /// Number of spaces per indent level
    public var indentSize: Int
    
    /// Line ending style
    public var endOfLine: EndOfLine
    
    /// Whether to insert a final newline at end of file
    public var insertFinalNewline: Bool
    
    /// Whether to trim trailing whitespace on each line
    public var trimTrailingWhitespace: Bool
    
    public enum IndentStyle {
        case space
    }
    
    public enum EndOfLine {
        case lf
        case crlf
        
        var string: String {
            switch self {
            case .lf: return "\n"
            case .crlf: return "\r\n"
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
    
    /// Create an indent string for the given level
    func indent(level: Int) -> String {
        String(repeating: " ", count: indentSize * level)
    }
}
