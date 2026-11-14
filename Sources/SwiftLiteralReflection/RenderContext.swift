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
  ///
  /// Built on demand from a chain of components. Only an error message reads it, and building an array
  /// for every value on the way down was a large share of a render's allocations.
  public var path: [String] { trail.components }

  /// Where this value is, as a chain back to the root.
  let trail: PathTrail

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
      trail: PathTrail(root: path), options: options, renderers: renderers, openObjects: [],
      typeNames: TypeNameCache())
  }

  init(
    trail: PathTrail,
    options: RenderOptions,
    renderers: ValueRenderers,
    openObjects: Set<ObjectIdentifier>,
    typeNames: TypeNameCache
  ) {
    self.trail = trail
    self.options = options
    self.renderers = renderers
    self.openObjects = openObjects
    self.typeNames = typeNames
  }

  /// A child context one level deeper.
  public func appending(path component: String) -> RenderContext {
    appending(.name(component))
  }

  func appending(_ component: PathTrail.Component) -> RenderContext {
    RenderContext(
      trail: PathTrail(parent: trail, component: component),
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
      trail: trail,
      options: options,
      renderers: renderers,
      openObjects: openObjects.union([ObjectIdentifier(object)]),
      typeNames: typeNames
    )
  }
}

/// The path to a value, from the value back to the root.
///
/// A component is kept in the form it was found in and only turned into text when
/// ``components`` is read, which is when a render fails.
final class PathTrail: Sendable {
  enum Component: Sendable {
    case name(String)
    /// `[3]`, an array element.
    case index(Int)
    /// `["key"]`, a dictionary value under its rendered key.
    case key(String)
    /// `.0`, a tuple element.
    case element(Int)
    /// `move.1`, an associated value of an enum case.
    case associatedValue(String, Int)

    var text: String {
      switch self {
      case .name(let name): name
      case .index(let index): "[\(index)]"
      case .key(let key): "[\(key)]"
      case .element(let index): ".\(index)"
      case .associatedValue(let name, let index): "\(name).\(index)"
      }
    }
  }

  private let parent: PathTrail?
  private let component: Component?
  private let root: [String]

  init(root: [String]) {
    self.parent = nil
    self.component = nil
    self.root = root
  }

  init(parent: PathTrail, component: Component) {
    self.parent = parent
    self.component = component
    self.root = []
  }

  var components: [String] {
    var reversed: [String] = []
    var node: PathTrail? = self
    while let current = node {
      if let component = current.component {
        reversed.append(component.text)
      } else {
        reversed.append(contentsOf: current.root.reversed())
      }
      node = current.parent
    }
    return reversed.reversed()
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
