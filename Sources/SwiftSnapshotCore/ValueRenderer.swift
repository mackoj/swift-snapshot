import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// Core value renderer that converts Swift values to ExprSyntax
///
/// `ValueRenderer` is the heart of SwiftSnapshot's code generation. It traverses values
/// and converts them to SwiftSyntax expressions that can be formatted and written to files.
///
/// ## Overview
///
/// The renderer uses a multi-stage approach:
/// 1. **Custom Renderers**: Check ``SnapshotRendererRegistry`` for user-defined handlers
/// 2. **Primitives**: Handle built-in Swift types (String, Int, Bool, etc.)
/// 3. **Collections**: Handle Array, Dictionary, Set with deterministic ordering
/// 4. **Foundation Types**: Handle Date, UUID, URL, Data, Decimal
/// 5. **Generic Collections**: Handle types conforming to Collection protocol
/// 6. **Reflection**: Fall back to Mirror-based rendering for custom types
///
/// ## Supported Types
///
/// ### Primitives
/// - String, Int (all variants: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64), Double, Float, Bool, Character
///
/// ### Collections
/// - Array, Dictionary (with sorted keys), Set (with deterministic ordering)
/// - Generic Collection types (e.g., IdentifiedArray, custom collections)
/// - Optional values (nil handling)
///
/// ### Foundation
/// - Date (as `timeIntervalSince1970`)
/// - UUID (as `uuidString`)
/// - URL (as `string`)
/// - Data (hex array or base64)
/// - Decimal
///
/// ### Custom Types
/// - Structs, classes, enums via reflection
/// - User types via ``SnapshotRendererRegistry``
///
/// ## Example Output
///
/// ```swift
/// // String
/// "Hello, World!"
///
/// // Date
/// Date(timeIntervalSince1970: 1234567890.0)
///
/// // Array
/// [1, 2, 3, 4, 5]
///
/// // Dictionary (sorted keys)
/// ["apple": 1, "banana": 2, "cherry": 3]
///
/// // Custom struct (via reflection)
/// User(id: 42, name: "Alice", active: true)
/// ```
///
/// ## See Also
/// - ``SnapshotRendererRegistry`` for custom type handling
/// - ``SnapshotRenderContext`` for rendering configuration
/// - ``SwiftSnapshotError`` for error handling
enum ValueRenderer {
  /// Render any value to a Swift expression
  ///
  /// The main entry point for value rendering. Routes values through the appropriate
  /// renderer based on type, checking custom renderers first.
  ///
  /// ## Rendering Priority
  ///
  /// 1. Custom renderers from ``SnapshotRendererRegistry``
  /// 2. Built-in primitive renderers
  /// 3. Optional handling
  /// 4. Collection renderers (Array, Dictionary, Set)
  /// 5. Foundation type renderers (Date, UUID, URL, Data, Decimal)
  /// 6. Generic Collection types (any type conforming to Collection protocol)
  /// 7. Reflection-based fallback
  ///
  /// - Parameters:
  ///   - value: The value to render (can be any type)
  ///   - context: Rendering context with formatting and path information
  ///
  /// - Returns: SwiftSyntax expression representing the value
  ///
  /// - Throws:
  ///   - ``SwiftSnapshotError/unsupportedType(_:path:)`` if type cannot be rendered
  ///   - ``SwiftSnapshotError/reflection(_:path:)`` if reflection fails
  static func render(_ value: Any, context: SnapshotRenderContext) throws -> ExprSyntax {
    // Check custom renderers first
    if let customRenderer = SnapshotRendererRegistry.shared.renderer(for: value) {
      return try customRenderer(value, context)
    }

    // Check if type conforms to SwiftSnapshotExportable and use its makeExpr method
    if let exportable = value as? any SwiftSnapshotExportable {
      return try renderSwiftSnapshotExportable(exportable, context: context)
    }

    // Handle primitives
    switch value {
    case let v as String:
      return try renderString(v)
    case let v as Int:
      return renderInt(v)
    case let v as Int8:
      return renderInt8(v)
    case let v as Int16:
      return renderInt16(v)
    case let v as Int32:
      return renderInt32(v)
    case let v as Int64:
      return renderInt64(v)
    case let v as UInt:
      return renderUInt(v)
    case let v as UInt8:
      return renderUInt8(v)
    case let v as UInt16:
      return renderUInt16(v)
    case let v as UInt32:
      return renderUInt32(v)
    case let v as UInt64:
      return renderUInt64(v)
    case let v as Double:
      return renderDouble(v)
    case let v as Float:
      return renderFloat(v)
    case let v as Bool:
      return renderBool(v)
    case let v as Character:
      return try renderCharacter(v)
    default:
      break
    }

    // Handle Optional
    if let optional = value as? (any OptionalProtocol) {
      return try renderOptional(optional, context: context)
    }

    // Handle collections
    if let array = value as? [Any] {
      return try renderArray(array, context: context)
    }

    if let dict = value as? [AnyHashable: Any] {
      return try renderDictionary(dict, context: context)
    }

    if let set = value as? Set<AnyHashable> {
      return try renderSet(set, context: context)
    }

    // Handle Foundation types
    if let date = value as? Date {
      return renderDate(date)
    }

    if let uuid = value as? UUID {
      return renderUUID(uuid)
    }

    if let url = value as? URL {
      return try renderURL(url)
    }

    if let data = value as? Data {
      return try renderData(data, context: context)
    }

    if let decimal = value as? Decimal {
      return renderDecimal(decimal)
    }

    // Handle generic Collection types (e.g., IdentifiedArray)
    // This must come after specific Array/Dictionary/Set/Data checks to avoid false matches
    // Data conforms to Collection but has its own specialized handler above
    if let collection = value as? any Collection {
      return try renderCollection(collection, context: context)
    }

    // Fallback to reflection
    return try renderViaReflection(value, context: context)
  }

  // MARK: - Primitive Renderers

  static func renderString(_ value: String) throws -> ExprSyntax {
    let escaped = escapeString(value)
    return ExprSyntax(StringLiteralExprSyntax(content: escaped))
  }

  static func renderInt(_ value: Int) -> ExprSyntax {
    ExprSyntax(IntegerLiteralExprSyntax(integerLiteral: value))
  }

  static func renderInt8(_ value: Int8) -> ExprSyntax {
    ExprSyntax(stringLiteral: "Int8(\(value))")
  }

  static func renderInt16(_ value: Int16) -> ExprSyntax {
    ExprSyntax(stringLiteral: "Int16(\(value))")
  }

  static func renderInt32(_ value: Int32) -> ExprSyntax {
    ExprSyntax(stringLiteral: "Int32(\(value))")
  }

  static func renderInt64(_ value: Int64) -> ExprSyntax {
    ExprSyntax(stringLiteral: "Int64(\(value))")
  }

  static func renderUInt(_ value: UInt) -> ExprSyntax {
    ExprSyntax(stringLiteral: "UInt(\(value))")
  }

  static func renderUInt8(_ value: UInt8) -> ExprSyntax {
    ExprSyntax(stringLiteral: "UInt8(\(value))")
  }

  static func renderUInt16(_ value: UInt16) -> ExprSyntax {
    ExprSyntax(stringLiteral: "UInt16(\(value))")
  }

  static func renderUInt32(_ value: UInt32) -> ExprSyntax {
    ExprSyntax(stringLiteral: "UInt32(\(value))")
  }

  static func renderUInt64(_ value: UInt64) -> ExprSyntax {
    ExprSyntax(stringLiteral: "UInt64(\(value))")
  }

  static func renderDouble(_ value: Double) -> ExprSyntax {
    if value.isNaN {
      return ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Double"))),
          dot: .periodToken(),
          name: .identifier("nan")
        ))
    } else if value.isInfinite {
      let sign = value > 0 ? "" : "-"
      return ExprSyntax(stringLiteral: "\(sign)Double.infinity")
    } else {
      return ExprSyntax(
        FloatLiteralExprSyntax(floatingDigits: .floatLiteral(String(format: "%.15g", value))))
    }
  }

  static func renderFloat(_ value: Float) -> ExprSyntax {
    if value.isNaN {
      return ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Float"))),
          dot: .periodToken(),
          name: .identifier("nan")
        ))
    } else if value.isInfinite {
      let sign = value > 0 ? "" : "-"
      return ExprSyntax(stringLiteral: "\(sign)Float.infinity")
    } else {
      return ExprSyntax(FloatLiteralExprSyntax(floatingDigits: .floatLiteral("\(value)")))
    }
  }

  static func renderBool(_ value: Bool) -> ExprSyntax {
    ExprSyntax(BooleanLiteralExprSyntax(booleanLiteral: value))
  }

  static func renderCharacter(_ value: Character) throws -> ExprSyntax {
    let escaped = escapeString(String(value))
    return ExprSyntax(stringLiteral: "Character(\"\(escaped)\")")
  }

  // MARK: - Foundation Type Renderers

  static func renderDate(_ value: Date) -> ExprSyntax {
    let interval = value.timeIntervalSince1970
    return ExprSyntax(stringLiteral: "Date(timeIntervalSince1970: \(interval))")
  }

  static func renderUUID(_ value: UUID) -> ExprSyntax {
    let uuidString = value.uuidString
    return ExprSyntax(stringLiteral: "UUID(uuidString: \"\(uuidString)\")!")
  }

  static func renderURL(_ value: URL) throws -> ExprSyntax {
    let urlString = value.absoluteString
    let escaped = escapeString(urlString)
    return ExprSyntax(stringLiteral: "URL(string: \"\(escaped)\")!")
  }

  static func renderData(_ value: Data, context: SnapshotRenderContext) throws -> ExprSyntax {
    if value.count <= context.options.dataInlineThreshold {
      // Inline as hex array
      let hexBytes = value.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
      return ExprSyntax(stringLiteral: "Data([\(hexBytes)])")
    } else {
      // Base64 encoded
      let base64 = value.base64EncodedString()
      return ExprSyntax(stringLiteral: "Data(base64Encoded: \"\(base64)\")!")
    }
  }

  static func renderDecimal(_ value: Decimal) -> ExprSyntax {
    let description = value.description
    return ExprSyntax(stringLiteral: "Decimal(string: \"\(description)\")!")
  }

  // MARK: - Collection Renderers

  static func renderOptional(_ value: any OptionalProtocol, context: SnapshotRenderContext) throws
    -> ExprSyntax
  {
    guard let wrapped = value.wrappedValue else {
      return ExprSyntax(NilLiteralExprSyntax())
    }
    return try render(wrapped, context: context)
  }

  static func renderArray(_ array: [Any], context: SnapshotRenderContext) throws -> ExprSyntax {
    if array.isEmpty {
      return ExprSyntax(ArrayExprSyntax(elements: ArrayElementListSyntax([])))
    }

    var elements: [ArrayElementSyntax] = []
    for (index, element) in array.enumerated() {
      let elementContext = context.appending(path: "[\(index)]")
      let expr = try render(element, context: elementContext)
      elements.append(
        ArrayElementSyntax(
          expression: expr,
          trailingComma: index < array.count - 1 ? .commaToken() : nil
        ))
    }

    return ExprSyntax(ArrayExprSyntax(elements: ArrayElementListSyntax(elements)))
  }

  static func renderDictionary(_ dict: [AnyHashable: Any], context: SnapshotRenderContext) throws
    -> ExprSyntax
  {
    if dict.isEmpty {
      return ExprSyntax(DictionaryExprSyntax(content: .colon(.colonToken())))
    }

    var pairs: [(key: String, value: Any)] = []
    for (key, value) in dict {
      pairs.append((key: "\(key)", value: value))
    }

    // Sort if requested
    if context.options.sortDictionaryKeys {
      pairs.sort { $0.key < $1.key }
    }

    var elements: [DictionaryElementSyntax] = []
    for (index, pair) in pairs.enumerated() {
      let keyContext = context.appending(path: "[\(pair.key)]")
      let keyExpr = try render(pair.key, context: keyContext)
      let valueExpr = try render(pair.value, context: keyContext)
      elements.append(
        DictionaryElementSyntax(
          key: keyExpr,
          value: valueExpr,
          trailingComma: index < pairs.count - 1 ? .commaToken() : nil
        ))
    }

    return ExprSyntax(
      DictionaryExprSyntax(
        content: .elements(DictionaryElementListSyntax(elements))
      ))
  }

  static func renderSet(_ set: Set<AnyHashable>, context: SnapshotRenderContext) throws
    -> ExprSyntax
  {
    var elements = Array(set)

    // Sort for determinism if requested
    if context.options.setDeterminism {
      elements.sort { "\($0)" < "\($1)" }
    }

    let arrayExpr = try renderArray(elements, context: context)
    return ExprSyntax(stringLiteral: "Set(\(arrayExpr))")
  }

  /// Render generic Collection types
  ///
  /// Handles any type conforming to the Collection protocol that isn't handled by
  /// more specific renderers (Array, Dictionary, Set, Data).
  ///
  /// This is particularly useful for generic collection types like IdentifiedArray,
  /// custom collection wrappers, and other specialized collection types.
  ///
  /// ## Output Format
  ///
  /// ```swift
  /// TypeName<Element>([element1, element2, ...])
  /// ```
  ///
  /// ## Example
  ///
  /// ```swift
  /// // Input: IdentifiedArray<Int, Person>([Person(id: 1, name: "Alice")])
  /// // Output: IdentifiedArray<Int, Person>([Person(id: 1, name: "Alice")])
  /// ```
  ///
  /// - Parameters:
  ///   - collection: The collection to render
  ///   - context: Rendering context with formatting and path information
  ///
  /// - Returns: SwiftSyntax expression representing the collection
  ///
  /// - Throws: ``SwiftSnapshotError`` if elements cannot be rendered
  static func renderCollection(_ collection: any Collection, context: SnapshotRenderContext) throws
    -> ExprSyntax
  {
    // Convert collection to array of Any for rendering
    var elements: [Any] = []
    for element in collection {
      elements.append(element)
    }
    
    let arrayExpr = try renderArray(elements, context: context)
    
    // Get the type name for the collection
    let typeName = String(describing: type(of: collection))
    
    // Return as TypeName(arrayLiteral: [...])
    return ExprSyntax(stringLiteral: "\(typeName)(\(arrayExpr))")
  }

  // MARK: - Reflection Fallback

  static func renderViaReflection(_ value: Any, context: SnapshotRenderContext) throws -> ExprSyntax
  {
    let mirror = Mirror(reflecting: value)
    let typeName = String(describing: type(of: value))

    // Handle enums
    if mirror.displayStyle == .enum {
      return try renderEnumViaReflection(value, mirror: mirror, context: context)
    }

    // Handle structs and classes
    if mirror.displayStyle == .struct || mirror.displayStyle == .class {
      return try renderStructViaReflection(
        value, typeName: typeName, mirror: mirror, context: context)
    }

    throw SwiftSnapshotError.unsupportedType(typeName, path: context.path)
  }

  static func renderEnumViaReflection(_ value: Any, mirror: Mirror, context: SnapshotRenderContext)
    throws -> ExprSyntax
  {
    // Try RawRepresentable first
    if let rawRep = value as? any RawRepresentable {
      let rawValue = rawRep.rawValue
      let typeName = String(describing: type(of: value))

      // Try to use dot syntax for simple cases
      if context.options.forceEnumDotSyntax {
        let caseName = "\(value)"
        // Simple heuristic: if description looks like a case name
        if caseName.first?.isLetter == true && !caseName.contains("(") {
          return ExprSyntax(stringLiteral: ".\(caseName)")
        }
      }

      // Fallback to rawValue initializer
      let rawExpr = try render(rawValue, context: context)
      return ExprSyntax(stringLiteral: "\(typeName)(rawValue: \(rawExpr))!")
    }

    // Associated values - best effort
    if mirror.children.count > 0 {
      let caseName = "\(value)".split(separator: "(").first ?? ""
      var args: [String] = []
      for (index, child) in mirror.children.enumerated() {
        let childContext = context.appending(path: ".\(caseName)[\(index)]")
        let childExpr = try render(child.value, context: childContext)
        if let label = child.label {
          args.append("\(label): \(childExpr)")
        } else {
          args.append("\(childExpr)")
        }
      }
      let argsStr = args.joined(separator: ", ")
      return ExprSyntax(stringLiteral: ".\(caseName)(\(argsStr))")
    }

    // Simple case with no associated values
    let caseName = "\(value)"
    return ExprSyntax(stringLiteral: ".\(caseName)")
  }

  static func renderStructViaReflection(
    _ value: Any, typeName: String, mirror: Mirror, context: SnapshotRenderContext
  ) throws -> ExprSyntax {
    var args: [String] = []

    for child in mirror.children {
      guard let label = child.label else {
        continue
      }

      let childContext = context.appending(path: label)
      let childExpr = try render(child.value, context: childContext)
      args.append("\(label): \(childExpr)")
    }

    let argsStr = args.joined(separator: ", ")
    return ExprSyntax(stringLiteral: "\(typeName)(\(argsStr))")
  }

  // MARK: - SwiftSnapshotExportable Renderer

  /// Render a type conforming to SwiftSnapshotExportable using its makeExpr method
  ///
  /// Types annotated with @SwiftSnapshot generate a `__swiftSnapshot_makeExpr` method
  /// that properly applies redactions and other transformations. This method uses
  /// that generated code to render the value correctly.
  ///
  /// - Parameters:
  ///   - exportable: The value conforming to SwiftSnapshotExportable
  ///   - context: Rendering context with formatting and path information
  ///
  /// - Returns: SwiftSyntax expression representing the value with redactions applied
  ///
  /// - Throws: ``SwiftSnapshotError`` if rendering fails
  static func renderSwiftSnapshotExportable(
    _ exportable: any SwiftSnapshotExportable,
    context: SnapshotRenderContext
  ) throws -> ExprSyntax {
    // Use a helper function to call the static method with the correct type
    func callMakeExpr<T: SwiftSnapshotExportable>(_ value: T) -> String {
      return T.__swiftSnapshot_makeExpr(from: value)
    }
    
    // Call the helper with the exportable value
    // This works because Swift will infer T from the runtime type
    let exprString = _openExistential(exportable, do: callMakeExpr)
    
    // Convert the string expression to ExprSyntax
    return ExprSyntax(stringLiteral: exprString)
  }

  // MARK: - String Escaping

  static func escapeString(_ value: String) -> String {
    var result = ""
    for char in value {
      switch char {
      case "\\": result.append("\\\\")
      case "\"": result.append("\\\"")
      case "\n": result.append("\\n")
      case "\r": result.append("\\r")
      case "\t": result.append("\\t")
      default:
        if char.unicodeScalars.first!.value < 32 || char.unicodeScalars.first!.value > 126 {
          // Use unicode escape for control characters and non-ASCII
          for scalar in char.unicodeScalars {
            result.append(String(format: "\\u{%X}", scalar.value))
          }
        } else {
          result.append(char)
        }
      }
    }
    return result
  }
}

// MARK: - Optional Protocol for Type Erasure

protocol OptionalProtocol {
  var wrappedValue: Any? { get }
}

extension Optional: OptionalProtocol {
  var wrappedValue: Any? {
    switch self {
    case .none: return nil
    case .some(let value): return value
    }
  }
}
