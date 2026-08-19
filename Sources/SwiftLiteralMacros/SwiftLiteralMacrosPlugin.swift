import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Plugin that provides the SwiftLiteral macro implementations.
@main
struct SwiftLiteralMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    SwiftLiteralMacro.self,
    LiteralIgnoreMacro.self,
    LiteralRenameMacro.self,
    LiteralRedactMacro.self,
  ]
}
