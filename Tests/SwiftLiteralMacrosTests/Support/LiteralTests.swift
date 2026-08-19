import MacroTesting
import SnapshotTesting
import Testing
import SwiftLiteralMacros

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "SwiftLiteral": SwiftLiteralMacro.self,
      "LiteralIgnore": LiteralIgnoreMacro.self,
      "LiteralRename": LiteralRenameMacro.self,
      "LiteralRedact": LiteralRedactMacro.self,
    ],
    record: .failed
  )
) struct LiteralTests {}
