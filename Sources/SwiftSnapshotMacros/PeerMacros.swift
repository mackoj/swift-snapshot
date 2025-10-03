import SwiftSyntax
import SwiftSyntaxMacros

/// Peer macro for @SnapshotIgnore - does not generate any code itself,
/// just marks the property for the parent @SwiftSnapshot macro to process.
public struct SnapshotIgnoreMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftSnapshotMacro
    return []
  }
}

/// Peer macro for @SnapshotRename - does not generate any code itself,
/// just marks the property for the parent @SwiftSnapshot macro to process.
public struct SnapshotRenameMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftSnapshotMacro
    return []
  }
}

/// Peer macro for @SnapshotRedact - does not generate any code itself,
/// just marks the property for the parent @SwiftSnapshot macro to process.
public struct SnapshotRedactMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // This macro doesn't generate any code - it's processed by SwiftSnapshotMacro
    return []
  }
}
