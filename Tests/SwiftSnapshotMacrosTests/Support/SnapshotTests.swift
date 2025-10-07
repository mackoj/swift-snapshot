import MacroTesting
import SnapshotTesting
import Testing
import SwiftSnapshotMacros

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "Snapshot": SwiftSnapshotMacro.self,
      "SwiftSnapshot": SwiftSnapshotMacro.self,
      "SnapshotIgnore": SnapshotIgnoreMacro.self,
      "SnapshotRename": SnapshotRenameMacro.self,
      "SnapshotRedact": SnapshotRedactMacro.self,
    ],
    record: .failed
  )
) struct SnapshotTests {}
