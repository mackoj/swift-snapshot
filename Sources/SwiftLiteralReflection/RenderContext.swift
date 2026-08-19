/// What a renderer knows about where it is.
///
/// The context carries three things: the options in force, the custom renderers in force,
/// and a breadcrumb path to the value being rendered. The path only feeds error messages.
/// A good error message is the difference between a five second fix and an hour.
///
/// Everything the engine needs is in here. It reads no globals, so the same value with the
/// same context renders the same way whatever else the process is doing.
public struct RenderContext: Sendable {
  /// Property names traversed to reach this value. `["profile", "address", "city"]`.
  public let path: [String]

  /// Options in force for this render.
  public let options: RenderOptions

  /// Custom renderers in force for this render.
  public let renderers: ValueRenderers

  public init(
    path: [String] = [],
    options: RenderOptions = .default,
    renderers: ValueRenderers = ValueRenderers()
  ) {
    self.path = path
    self.options = options
    self.renderers = renderers
  }

  /// A child context one level deeper.
  public func appending(path component: String) -> RenderContext {
    RenderContext(path: path + [component], options: options, renderers: renderers)
  }
}
