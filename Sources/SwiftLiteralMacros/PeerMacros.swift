import SwiftSyntax
import SwiftSyntaxMacros

/// Peer macro for @LiteralIgnore - does not generate any code itself,
/// just marks the property for the parent @SwiftLiteral macro to process.
public struct LiteralIgnoreMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftLiteralMacro
    return []
  }
}

/// Peer macro for @LiteralRename - does not generate any code itself,
/// just marks the property for the parent @SwiftLiteral macro to process.
public struct LiteralRenameMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftLiteralMacro
    return []
  }
}

/// Peer macro for @LiteralRedact - does not generate any code itself,
/// just marks the property for the parent @SwiftLiteral macro to process.
public struct LiteralRedactMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftLiteralMacro
    return []
  }
}
