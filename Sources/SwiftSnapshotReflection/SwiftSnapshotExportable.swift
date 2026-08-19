/// The hook the `@SwiftSnapshot` macro uses to hand the renderer a field list.
///
/// Reflection alone cannot see `@SnapshotRedact`, `@SnapshotRename`, or
/// `@SnapshotIgnore`. Those live in the source, not in the runtime value. The macro
/// reads them at compile time and emits this method, which returns the fields the
/// way they should be rendered.
///
/// You never write a conformance by hand. The macro does it.
public protocol SwiftSnapshotExportable {
  /// Fields in declaration order, with attribute transforms already applied.
  func __swiftSnapshot_reflectionFields() -> [SwiftSnapshotReflectionField]
}

/// One field, ready to render.
public struct SwiftSnapshotReflectionField {
  /// The argument label to emit.
  public let label: String

  /// The value to render, or the redacted stand-in.
  public let value: Any

  public init(label: String, value: Any) {
    self.label = label
    self.value = value
  }
}
