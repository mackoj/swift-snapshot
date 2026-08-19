import Foundation
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

/// Turns a runtime value into the Swift expression that rebuilds it.
///
/// This is the whole engine. Everything else in the package formats what comes out
/// of here or decides where to write it.
///
/// The renderer builds source text, then parses it once at the top. If the text does
/// not parse, rendering fails. A fixture that does not compile is worse than no
/// fixture, so the renderer throws rather than guess.
///
/// Order of attempts, per value:
///
/// 1. Optionals are unwrapped first, so a custom renderer for `T` also covers `T?`.
/// 2. Custom renderers from ``SnapshotRendererRegistry``.
/// 3. Types the `@SwiftSnapshot` macro described, via ``SwiftSnapshotExportable``.
/// 4. Primitives and Foundation types.
/// 5. Arrays, dictionaries, sets, ranges.
/// 6. Reflection over structs, classes, and enums.
public enum ValueRenderer {
  /// Render a value as a Swift expression.
  ///
  /// - Throws: ``SwiftSnapshotError/unsupportedType(_:path:)`` when nothing can read
  ///   the value, or ``SwiftSnapshotError/reflection(_:path:)`` when the text it
  ///   produced does not parse.
  public static func render(_ value: Any, context: SnapshotRenderContext = .init()) throws
    -> ExprSyntax
  {
    let source = try text(value, context: context)
    let parsed = Parser.parse(source: source)
    let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: parsed)
    guard diagnostics.isEmpty,
      let statement = parsed.statements.first,
      let expression = statement.item.as(ExprSyntax.self)
    else {
      throw SwiftSnapshotError.reflection(
        "Rendered source does not parse as an expression: \(source)",
        path: context.path
      )
    }
    return expression
  }

  // MARK: - Text

  static func text(_ value: Any, context: SnapshotRenderContext) throws -> String {
    // Optionals first, so a renderer registered for `T` also covers `T?`.
    if let optional = value as? any OptionalProtocol {
      guard let wrapped = optional.snapshotWrappedValue else { return "nil" }
      // A non-nil optional of an optional needs the `.some` back, or `Int??.some(nil)`
      // would render as plain `nil` and come back as a different value.
      let inner = try text(wrapped, context: context)
      return wrapped is any OptionalProtocol ? ".some(\(inner))" : inner
    }

    if let custom = SnapshotRendererRegistry.shared.renderer(for: value) {
      return try custom(value, context).description
    }

    if let exportable = value as? any SwiftSnapshotExportable,
      let rendered = try exportableText(exportable, context: context)
    {
      return rendered
    }

    if let primitive = primitiveText(value) { return primitive }
    if let foundation = try foundationText(value, context: context) { return foundation }
    if let collection = try collectionText(value, context: context) { return collection }

    return try reflectedText(value, context: context)
  }

  // MARK: - Primitives

  /// Integers render as bare digits, and sized integers rely on the literal
  /// converting at the use site. `Int8(3)` and `3` mean the same thing in an
  /// `Int8` position, and the short one reads better in a fixture.
  private static func primitiveText(_ value: Any) -> String? {
    switch value {
    case let v as String: return quoted(v)
    case let v as Bool: return v ? "true" : "false"
    case let v as Character: return "Character(\(quoted(String(v))))"
    case let v as any BinaryInteger: return String(describing: v)
    case let v as Double: return floating(v, type: "Double")
    case let v as Float: return floating(v, type: "Float")
    default: return nil
    }
  }

  /// Swift prints the shortest representation that round-trips, so string
  /// interpolation is exact here. Infinity and NaN have no literal form.
  private static func floating<F: BinaryFloatingPoint & LosslessStringConvertible>(
    _ value: F, type: String
  ) -> String {
    if value.isNaN { return "\(type).nan" }
    if value.isInfinite { return value < 0 ? "-\(type).infinity" : "\(type).infinity" }
    let description = String(value)
    // `String(1)` on a Double gives "1.0", but be sure: an integral-looking literal
    // would type-check as Int in an `Any` position.
    return description.contains(where: { $0 == "." || $0 == "e" }) ? description : description + ".0"
  }

  // MARK: - Foundation

  private static func foundationText(_ value: Any, context: SnapshotRenderContext) throws -> String?
  {
    switch value {
    case let v as Date:
      return "Date(timeIntervalSince1970: \(floating(v.timeIntervalSince1970, type: "Double")))"
    case let v as UUID:
      return "UUID(uuidString: \(quoted(v.uuidString)))!"
    case let v as URL:
      return "URL(string: \(quoted(v.absoluteString)))!"
    case let v as Decimal:
      return "Decimal(string: \(quoted(v.description)))!"
    case let v as Data:
      if v.count <= context.options.dataInlineThreshold {
        let bytes = v.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
        return "Data([\(bytes)])"
      }
      return "Data(base64Encoded: \(quoted(v.base64EncodedString())))!"
    default:
      return nil
    }
  }

  // MARK: - Collections

  /// Collections go through `Mirror`, not through `as? [Any]`.
  ///
  /// Casting a `[Int: String]` to `[AnyHashable: Any]` erases the key type, and the
  /// keys then render as strings. `["1": "a"]` is not `[1: "a"]` and does not compile.
  private static func collectionText(_ value: Any, context: SnapshotRenderContext) throws -> String?
  {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .collection:
      let elements = try mirror.children.enumerated().map { index, child in
        try text(child.value, context: context.appending(path: "[\(index)]"))
      }
      return elements.isEmpty ? "[]" : "[\(elements.joined(separator: ", "))]"

    case .set:
      // A set literal is an array literal. `Set([1, 2])` needs the element type to be
      // inferable from the argument; `[1, 2]` reads it off the parameter instead.
      var elements = try mirror.children.map {
        try text($0.value, context: context.appending(path: "[]"))
      }
      if context.options.setDeterminism { elements.sort() }
      return elements.isEmpty ? "[]" : "[\(elements.joined(separator: ", "))]"

    case .dictionary:
      var pairs: [(key: String, value: String)] = []
      for child in mirror.children {
        let entry = Mirror(reflecting: child.value).children.map(\.value)
        guard entry.count == 2 else {
          throw SwiftSnapshotError.reflection(
            "Dictionary entry is not a key/value pair", path: context.path)
        }
        let key = try text(entry[0], context: context.appending(path: "[key]"))
        let value = try text(entry[1], context: context.appending(path: "[\(key)]"))
        pairs.append((key, value))
      }
      if context.options.sortDictionaryKeys { pairs.sort { $0.key < $1.key } }
      return pairs.isEmpty
        ? "[:]" : "[\(pairs.map { "\($0.key): \($0.value)" }.joined(separator: ", "))]"

    default:
      return try rangeText(value, context: context)
    }
  }

  /// Ranges reflect as plain structs with `lowerBound` and `upperBound`, and there is
  /// no initializer taking those labels. They need their operator form.
  private static func rangeText(_ value: Any, context: SnapshotRenderContext) throws -> String? {
    let typeName = String(describing: type(of: value))
    let mirror = Mirror(reflecting: value)
    let bounds = Dictionary(
      uniqueKeysWithValues: mirror.children.compactMap { child -> (String, Any)? in
        child.label.map { ($0, child.value) }
      })
    guard let lower = bounds["lowerBound"], let upper = bounds["upperBound"], bounds.count == 2
    else { return nil }

    let operatorText: String
    if typeName.hasPrefix("ClosedRange<") {
      operatorText = "..."
    } else if typeName.hasPrefix("Range<") {
      operatorText = "..<"
    } else {
      return nil
    }
    let lowerText = try text(lower, context: context.appending(path: "lowerBound"))
    let upperText = try text(upper, context: context.appending(path: "upperBound"))
    return "\(lowerText)\(operatorText)\(upperText)"
  }

  // MARK: - Reflection

  private static func reflectedText(_ value: Any, context: SnapshotRenderContext) throws -> String {
    let typeName = String(describing: type(of: value))
    let mirror = Mirror(reflecting: value)

    switch mirror.displayStyle {
    case .enum:
      return try enumText(value, typeName: typeName, mirror: mirror, context: context)
    case .struct, .class:
      return try structText(value, typeName: typeName, mirror: mirror, context: context)
    default:
      throw SwiftSnapshotError.unsupportedType(typeName, path: context.path)
    }
  }

  private static func enumText(
    _ value: Any, typeName: String, mirror: Mirror, context: SnapshotRenderContext
  ) throws -> String {
    let caseName = enumCaseName(value)
    let prefix = context.options.forceEnumDotSyntax ? "." : "\(typeName)."

    guard let child = mirror.children.first else {
      if let name = caseName { return "\(prefix)\(name)" }
      // No payload and no case name means the enum is imported or otherwise opaque.
      // A raw value still rebuilds it exactly.
      if let raw = (value as? any RawRepresentable)?.rawValue {
        let rawText = try text(raw, context: context.appending(path: "rawValue"))
        return "\(typeName)(rawValue: \(rawText))!"
      }
      throw SwiftSnapshotError.unsupportedType(typeName, path: context.path)
    }

    // With a payload, the case name is the child's label and the payload is its value.
    let name = child.label ?? caseName
    guard let name else {
      throw SwiftSnapshotError.unsupportedType(typeName, path: context.path)
    }

    let payload = Mirror(reflecting: child.value)
    let arguments: [String]
    if payload.displayStyle == .tuple {
      // Multiple associated values arrive as one tuple. Its labels are the parameter
      // names, or ".0", ".1" when the case declared them without labels.
      arguments = try payload.children.enumerated().map { index, element in
        let rendered = try text(
          element.value, context: context.appending(path: "\(name).\(index)"))
        guard let label = element.label, !label.hasPrefix(".") else { return rendered }
        return "\(label): \(rendered)"
      }
    } else {
      arguments = [try text(child.value, context: context.appending(path: "\(name).0"))]
    }
    return "\(prefix)\(name)(\(arguments.joined(separator: ", ")))"
  }

  private static func structText(
    _ value: Any, typeName: String, mirror: Mirror, context: SnapshotRenderContext
  ) throws -> String {
    var arguments: [String] = []
    for child in mirror.children {
      guard let label = child.label else {
        throw SwiftSnapshotError.reflection(
          "'\(typeName)' has an unlabelled stored property, so no initializer call can be built",
          path: context.path
        )
      }
      let (name, unwrapped) = try propertyWrapperValue(label: label, value: child.value, context: context)
      let rendered = try text(unwrapped, context: context.appending(path: name))
      arguments.append("\(name): \(rendered)")
    }
    if arguments.isEmpty, mirror.displayStyle == .class {
      // A class with no stored properties reflects as empty whether or not it has an
      // initializer worth calling. Say so instead of emitting `Type()` and hoping.
      throw SwiftSnapshotError.unsupportedType(typeName, path: context.path)
    }
    return "\(typeName)(\(arguments.joined(separator: ", ")))"
  }

  /// Fields the `@SwiftSnapshot` macro extracted, applied at every depth.
  ///
  /// Depth matters. A redacted property nested three levels down is still a secret.
  private static func exportableText(
    _ exportable: any SwiftSnapshotExportable, context: SnapshotRenderContext
  ) throws -> String? {
    let fields = exportable.__swiftSnapshot_reflectionFields()
    guard !fields.isEmpty else { return nil }
    let typeName = String(describing: type(of: exportable))
    let arguments = try fields.map { field in
      "\(field.label): \(try text(field.value, context: context.appending(path: field.label)))"
    }
    return "\(typeName)(\(arguments.joined(separator: ", ")))"
  }

  /// Unwrap a property wrapper, or say why it cannot be unwrapped.
  ///
  /// A wrapper's backing storage is named `_name`. Two shapes are readable:
  /// a stored `wrappedValue`, or a single stored property that holds the value while
  /// `wrappedValue` is computed on top of it. Both are common.
  ///
  /// Wrappers that keep their value behind a pointer or in framework machinery, such
  /// as `@Published` or SwiftUI's `@State`, are not readable through `Mirror` at all.
  /// The library used to guess at those by casting the pointer to a list of likely
  /// types. It guessed wrong quietly. Now it says so. Mark them `@SnapshotIgnore`, or
  /// register a custom renderer.
  private static func propertyWrapperValue(
    label: String, value: Any, context: SnapshotRenderContext
  ) throws -> (String, Any) {
    guard label.hasPrefix("_") else { return (label, value) }
    let name = String(label.dropFirst())
    let children = Array(Mirror(reflecting: value).children)

    if let wrapped = children.first(where: { $0.label == "wrappedValue" }) {
      return (name, wrapped.value)
    }
    if children.count == 1, let only = children.first, !isPointer(only.value) {
      return (name, only.value)
    }
    throw SwiftSnapshotError.unsupportedType(
      String(describing: type(of: value)),
      path: context.path + [name]
    )
  }

  private static func isPointer(_ value: Any) -> Bool {
    let name = String(describing: type(of: value))
    return name.hasPrefix("Unsafe") && name.contains("Pointer")
  }

  // MARK: - Strings

  /// Escape only what has to be escaped.
  ///
  /// Accented letters and emoji stay as themselves. Swift source is UTF-8, and a
  /// fixture full of `\u{1F600}` is a fixture nobody reads.
  static func quoted(_ value: String) -> String {
    var result = "\""
    for character in value {
      switch character {
      case "\\": result += "\\\\"
      case "\"": result += "\\\""
      case "\n": result += "\\n"
      case "\r": result += "\\r"
      case "\t": result += "\\t"
      case "\0": result += "\\0"
      default:
        if let scalar = character.unicodeScalars.first,
          character.unicodeScalars.count == 1,
          scalar.properties.generalCategory == .control
        {
          result += String(format: "\\u{%X}", scalar.value)
        } else {
          result.append(character)
        }
      }
    }
    return result + "\""
  }
}

// MARK: - Enum case names

/// The runtime knows the case name even when the type overrides `description`.
///
/// `String(describing:)` is not usable here: a `CustomStringConvertible` enum returns
/// whatever it likes, and that text is not a case name.
@_silgen_name("swift_EnumCaseName")
private func _getEnumCaseName<T>(_ value: T) -> UnsafePointer<CChar>?

private func enumCaseName(_ value: Any) -> String? {
  func name<T>(_ value: T) -> String? {
    _getEnumCaseName(value).map { String(cString: $0) }
  }
  return _openExistential(value, do: name)
}

// MARK: - Optional erasure

/// `Any` hides whether a value is an optional. This protocol asks it directly.
protocol OptionalProtocol {
  var snapshotWrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
  var snapshotWrappedValue: Any? {
    switch self {
    case .none: nil
    case .some(let value): value
    }
  }
}
