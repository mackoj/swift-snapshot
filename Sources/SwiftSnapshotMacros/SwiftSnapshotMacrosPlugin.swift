import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Plugin that provides the SwiftSnapshot macro implementations.
@main
struct SwiftSnapshotMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    SwiftSnapshotMacro.self,
    SnapshotIgnoreMacro.self,
    SnapshotRenameMacro.self,
    SnapshotRedactMacro.self,
  ]
}
