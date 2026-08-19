/// What a renderer knows about where it is.
///
/// The context carries the options in force, the custom renderers in force, a breadcrumb
/// path to the value being rendered, and the class instances already on the way in. The
/// path only feeds error messages. A good error message is the difference between a five
/// second fix and an hour.
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

  /// Class instances already open further up the graph.
  ///
  /// Source is a tree and an object graph is not. Without this, two objects pointing at
  /// each other recurse until the stack runs out, which takes the process with it.
  let openObjects: Set<ObjectIdentifier>

  public init(
    path: [String] = [],
    options: RenderOptions = .default,
    renderers: ValueRenderers = ValueRenderers()
  ) {
    self.init(path: path, options: options, renderers: renderers, openObjects: [])
  }

  init(
    path: [String],
    options: RenderOptions,
    renderers: ValueRenderers,
    openObjects: Set<ObjectIdentifier>
  ) {
    self.path = path
    self.options = options
    self.renderers = renderers
    self.openObjects = openObjects
  }

  /// A child context one level deeper.
  public func appending(path component: String) -> RenderContext {
    RenderContext(
      path: path + [component],
      options: options,
      renderers: renderers,
      openObjects: openObjects
    )
  }

  func hasOpen(_ object: AnyObject) -> Bool {
    openObjects.contains(ObjectIdentifier(object))
  }

  func opening(_ object: AnyObject) -> RenderContext {
    RenderContext(
      path: path,
      options: options,
      renderers: renderers,
      openObjects: openObjects.union([ObjectIdentifier(object)])
    )
  }
}
