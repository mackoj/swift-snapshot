import Foundation

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

  /// Type names already worked out, shared by every context derived from this one.
  let typeNames: TypeNameCache

  public init(
    path: [String] = [],
    options: RenderOptions = .default,
    renderers: ValueRenderers = ValueRenderers()
  ) {
    self.init(
      path: path, options: options, renderers: renderers, openObjects: [],
      typeNames: TypeNameCache())
  }

  init(
    path: [String],
    options: RenderOptions,
    renderers: ValueRenderers,
    openObjects: Set<ObjectIdentifier>,
    typeNames: TypeNameCache
  ) {
    self.path = path
    self.options = options
    self.renderers = renderers
    self.openObjects = openObjects
    self.typeNames = typeNames
  }

  /// A child context one level deeper.
  public func appending(path component: String) -> RenderContext {
    RenderContext(
      path: path + [component],
      options: options,
      renderers: renderers,
      openObjects: openObjects,
      typeNames: typeNames
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
      openObjects: openObjects.union([ObjectIdentifier(object)]),
      typeNames: typeNames
    )
  }
}

/// The names `ValueRenderer.typeName(of:)` worked out, by type.
///
/// A name costs two runtime type-name lookups and a split, more than rendering the rest of a
/// small struct, and a fixture repeats a handful of types thousands of times. One cache per
/// render, carried in the context, so nothing outlives the render that filled it.
// Every access to `names` holds `lock`: a custom renderer may hand the context to another thread.
final class TypeNameCache: @unchecked Sendable {
  private let lock = NSLock()
  private var names: [ObjectIdentifier: String] = [:]

  func name(of type: Any.Type, orMake make: (Any.Type) -> String) -> String {
    let key = ObjectIdentifier(type)
    if let name = lock.withLock({ names[key] }) { return name }
    let name = make(type)
    lock.withLock { names[key] = name }
    return name
  }
}
