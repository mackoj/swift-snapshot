import MacroTesting
import SnapshotTesting
import Testing
import SwiftSnapshotMacrosPlugin

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "SwiftSnapshot": SwiftSnapshotMacro.self,
      "SnapshotIgnore": SnapshotIgnoreMacro.self,
      "SnapshotRename": SnapshotRenameMacro.self,
      "SnapshotRedact": SnapshotRedactMacro.self,
    ],
    record: .failed
  )
) struct SnapshotTests {}
