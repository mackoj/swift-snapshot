import SnapshotTesting
import Testing
import InlineSnapshotTesting

@MainActor @Suite(.serialized, .snapshots(record: .failed)) struct SnapshotTests {}
