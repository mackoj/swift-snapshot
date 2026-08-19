/// What a renderer knows about where it is.
///
/// The context carries two things: the options in force, and a breadcrumb path to
/// the value being rendered. The path only feeds error messages. A good error
/// message is the difference between a five second fix and an hour.
public struct SnapshotRenderContext: Sendable {
  /// Property names traversed to reach this value. `["profile", "address", "city"]`.
  public let path: [String]

  /// Options in force for this render.
  public let options: RenderOptions

  public init(path: [String] = [], options: RenderOptions = .default) {
    self.path = path
    self.options = options
  }

  /// A child context one level deeper.
  public func appending(path component: String) -> SnapshotRenderContext {
    SnapshotRenderContext(path: path + [component], options: options)
  }
}
