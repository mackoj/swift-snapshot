import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
import IssueReporting

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
    let typeName = String(describing: type(of: value))
    
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
      // Log when we're rendering an Optional at the top level (path is empty)
      if context.path.isEmpty {
        reportIssue(
          "Rendering top-level Optional of type '\(typeName)'. This will produce 'nil' if the optional is empty.",
          fileID: #fileID,
          filePath: #filePath,
          line: #line,
          column: #column
        )
      }
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

    // Check for unsafe pointer types - these cannot be serialized
    if typeName.hasPrefix("Unsafe") && typeName.contains("Pointer") {
      // Unsafe pointers are runtime memory addresses and cannot be meaningfully serialized
      reportIssue(
        "Cannot serialize unsafe pointer type '\(typeName)' at path '\(context.path.joined(separator: " → "))'. Using nil.",
        fileID: #fileID,
        filePath: #filePath,
        line: #line,
        column: #column
      )
      return ExprSyntax(NilLiteralExprSyntax())
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
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Int8")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderInt16(_ value: Int16) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Int16")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderInt32(_ value: Int32) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Int32")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderInt64(_ value: Int64) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Int64")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUInt(_ value: UInt) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UInt")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUInt8(_ value: UInt8) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UInt8")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUInt16(_ value: UInt16) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UInt16")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUInt32(_ value: UInt32) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UInt32")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUInt64(_ value: UInt64) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UInt64")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(value)))))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderDouble(_ value: Double) -> ExprSyntax {
    if value.isNaN {
      return ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Double"))),
          dot: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: .identifier("nan"))
        ))
    } else if value.isInfinite {
      let infinityExpr = ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Double"))),
          dot: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: .identifier("infinity"))
        ))
      
      if value > 0 {
        return infinityExpr
      } else {
        return ExprSyntax(
          PrefixOperatorExprSyntax(
            operator: .prefixOperator("-"),
            expression: infinityExpr
          )
        )
      }
    } else {
      return ExprSyntax(
        FloatLiteralExprSyntax(literal: .floatLiteral(String(format: "%.15g", value))))
    }
  }

  static func renderFloat(_ value: Float) -> ExprSyntax {
    if value.isNaN {
      return ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Float"))),
          dot: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: .identifier("nan"))
        ))
    } else if value.isInfinite {
      let infinityExpr = ExprSyntax(
        MemberAccessExprSyntax(
          base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Float"))),
          dot: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: .identifier("infinity"))
        ))
      
      if value > 0 {
        return infinityExpr
      } else {
        return ExprSyntax(
          PrefixOperatorExprSyntax(
            operator: .prefixOperator("-"),
            expression: infinityExpr
          )
        )
      }
    } else {
      return ExprSyntax(FloatLiteralExprSyntax(literal: .floatLiteral("\(value)")))
    }
  }

  static func renderBool(_ value: Bool) -> ExprSyntax {
    ExprSyntax(BooleanLiteralExprSyntax(booleanLiteral: value))
  }

  static func renderCharacter(_ value: Character) throws -> ExprSyntax {
    let escaped = escapeString(String(value))
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Character")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: ExprSyntax(StringLiteralExprSyntax(content: escaped)))
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  // MARK: - Foundation Type Renderers

  static func renderDate(_ value: Date) -> ExprSyntax {
    let interval = value.timeIntervalSince1970
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Date")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(
            label: .identifier("timeIntervalSince1970"),
            colon: .colonToken(),
            expression: ExprSyntax(FloatLiteralExprSyntax(literal: .floatLiteral(String(interval))))
          )
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  static func renderUUID(_ value: UUID) -> ExprSyntax {
    let uuidString = value.uuidString
    return ExprSyntax(
      ForceUnwrapExprSyntax(
        expression: FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(baseName: .identifier("UUID")),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(
              label: .identifier("uuidString"),
              colon: .colonToken(),
              expression: ExprSyntax(StringLiteralExprSyntax(content: uuidString))
            )
          ]),
          rightParen: .rightParenToken()
        ),
        exclamationMark: .exclamationMarkToken()
      )
    )
  }

  static func renderURL(_ value: URL) throws -> ExprSyntax {
    let urlString = value.absoluteString
    let escaped = escapeString(urlString)
    return ExprSyntax(
      ForceUnwrapExprSyntax(
        expression: FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(baseName: .identifier("URL")),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(
              label: .identifier("string"),
              colon: .colonToken(),
              expression: ExprSyntax(StringLiteralExprSyntax(content: escaped))
            )
          ]),
          rightParen: .rightParenToken()
        ),
        exclamationMark: .exclamationMarkToken()
      )
    )
  }

  static func renderData(_ value: Data, context: SnapshotRenderContext) throws -> ExprSyntax {
    if value.count <= context.options.dataInlineThreshold {
      // Inline as hex array
      let hexElementsRaw = value.map { byte -> ArrayElementSyntax in
        ArrayElementSyntax(
          expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral(String(format: "0x%02X", byte))))
        )
      }
      
      // Add trailing commas to array elements
      var hexElements: [ArrayElementSyntax] = []
      for (index, elem) in hexElementsRaw.enumerated() {
        if index < hexElementsRaw.count - 1 {
          hexElements.append(elem.with(\.trailingComma, .commaToken()))
        } else {
          hexElements.append(elem)
        }
      }
      
      return ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Data")),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(
              expression: ArrayExprSyntax(elements: ArrayElementListSyntax(hexElements))
            )
          ]),
          rightParen: .rightParenToken()
        )
      )
    } else {
      // Base64 encoded
      let base64 = value.base64EncodedString()
      return ExprSyntax(
        ForceUnwrapExprSyntax(
          expression: FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Data")),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
              LabeledExprSyntax(
                label: .identifier("base64Encoded"),
                colon: .colonToken(),
                expression: ExprSyntax(StringLiteralExprSyntax(content: base64))
              )
            ]),
            rightParen: .rightParenToken()
          ),
          exclamationMark: .exclamationMarkToken()
        )
      )
    }
  }

  static func renderDecimal(_ value: Decimal) -> ExprSyntax {
    let description = value.description
    return ExprSyntax(
      ForceUnwrapExprSyntax(
        expression: FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Decimal")),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(
              label: .identifier("string"),
              colon: .colonToken(),
              expression: ExprSyntax(StringLiteralExprSyntax(content: description))
            )
          ]),
          rightParen: .rightParenToken()
        ),
        exclamationMark: .exclamationMarkToken()
      )
    )
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
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Set")),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: arrayExpr)
        ]),
        rightParen: .rightParenToken()
      )
    )
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
    
    // Return as TypeName([...])
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier(typeName)),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: arrayExpr)
        ]),
        rightParen: .rightParenToken()
      )
    )
  }

  // MARK: - Reflection Fallback

  static func renderViaReflection(_ value: Any, context: SnapshotRenderContext) throws -> ExprSyntax
  {
    let mirror = Mirror(reflecting: value)
    let typeName = String(describing: type(of: value))

    // Log when we're at the top level to help diagnose issues
    if context.path.isEmpty {
      reportIssue(
        "Starting reflection-based rendering for type '\(typeName)' with displayStyle '\(String(describing: mirror.displayStyle))' and \(mirror.children.count) children",
        fileID: #fileID,
        filePath: #filePath,
        line: #line,
        column: #column
      )
    }

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
          return ExprSyntax(
            MemberAccessExprSyntax(
              dot: .periodToken(),
              declName: DeclReferenceExprSyntax(baseName: .identifier(caseName))
            )
          )
        }
      }

      // Fallback to rawValue initializer
      do {
        let rawExpr = try render(rawValue, context: context)
        return ExprSyntax(
          ForceUnwrapExprSyntax(
            expression: FunctionCallExprSyntax(
              calledExpression: DeclReferenceExprSyntax(baseName: .identifier(typeName)),
              leftParen: .leftParenToken(),
              arguments: LabeledExprListSyntax([
                LabeledExprSyntax(
                  label: .identifier("rawValue"),
                  colon: .colonToken(),
                  expression: rawExpr
                )
              ]),
              rightParen: .rightParenToken()
            ),
            exclamationMark: .exclamationMarkToken()
          )
        )
      } catch {
        // If we can't render the raw value, report and use a simple representation
        reportIssue(
          "Failed to render raw value for enum '\(typeName)': \(error). Using simple case representation.",
          fileID: #fileID,
          filePath: #filePath,
          line: #line,
          column: #column
        )
        let caseName = "\(value)"
        return ExprSyntax(
          MemberAccessExprSyntax(
            dot: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(caseName))
          )
        )
      }
    }

    // Associated values - best effort
    if mirror.children.count > 0 {
      let caseName = "\(value)".split(separator: "(").first ?? ""
      var labeledArgs: [LabeledExprSyntax] = []
      
      for (index, child) in mirror.children.enumerated() {
        let childContext = context.appending(path: ".\(caseName)[\(index)]")
        
        // Try to render the associated value, use nil as default if it fails
        let childExpr: ExprSyntax
        do {
          childExpr = try render(child.value, context: childContext)
        } catch {
          // Only report issues for shallow paths (not deep internal structures)
          if childContext.path.count <= 2 {
            reportIssue(
              "Failed to render associated value at index \(index) for enum case '\(caseName)'. Using nil.",
              fileID: #fileID,
              filePath: #filePath,
              line: #line,
              column: #column
            )
          }
          
          childExpr = ExprSyntax(NilLiteralExprSyntax())
        }
        
        if let label = child.label {
          labeledArgs.append(
            LabeledExprSyntax(
              label: .identifier(label),
              colon: .colonToken(),
              expression: childExpr
            )
          )
        } else {
          labeledArgs.append(
            LabeledExprSyntax(
              expression: childExpr
            )
          )
        }
      }
      
      // Add trailing commas
      var argsWithCommas: [LabeledExprSyntax] = []
      for (index, arg) in labeledArgs.enumerated() {
        if index < labeledArgs.count - 1 {
          argsWithCommas.append(arg.with(\.trailingComma, .commaToken()))
        } else {
          argsWithCommas.append(arg)
        }
      }
      
      // Build proper member access with function call
      return ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: MemberAccessExprSyntax(
            dot: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(String(caseName)))
          ),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax(argsWithCommas),
          rightParen: .rightParenToken()
        )
      )
    }

    // Simple case with no associated values
    let caseName = "\(value)"
    return ExprSyntax(
      MemberAccessExprSyntax(
        dot: .periodToken(),
        declName: DeclReferenceExprSyntax(baseName: .identifier(caseName))
      )
    )
  }

  static func renderStructViaReflection(
    _ value: Any, typeName: String, mirror: Mirror, context: SnapshotRenderContext
  ) throws -> ExprSyntax {
    var labeledArgs: [LabeledExprSyntax] = []
    
    // Log at top level for debugging
    if context.path.isEmpty {
      reportIssue(
        "Rendering struct/class '\(typeName)' with \(mirror.children.count) children",
        fileID: #fileID,
        filePath: #filePath,
        line: #line,
        column: #column
      )
    }

    for child in mirror.children {
      guard let label = child.label else {
        continue
      }

      // Check if this is a property wrapper (backing storage starts with "_")
      let (propertyName, propertyValue) = extractPropertyWrapperValue(label: label, value: child.value)
      
      let childContext = context.appending(path: propertyName)
      
      // Try to render the property value, but if it fails, use a default value and report the issue
      let childExpr: ExprSyntax
      do {
        childExpr = try render(propertyValue, context: childContext)
      } catch {
        // Check if we're deep in an internal structure (like Combine publishers)
        // If so, reduce the verbosity of error reporting
        let pathString = childContext.path.joined(separator: " → ")
        let isDeepInternalPath = pathString.contains("publisher") || 
                                  pathString.contains("subject") || 
                                  pathString.contains("subscriber") ||
                                  childContext.path.count > 3
        
        if !isDeepInternalPath {
          // Only report issues for top-level or user-facing properties
          let propertyTypeName = String(describing: type(of: propertyValue))
          reportIssue(
            "Failed to render property '\(propertyName)' of type '\(propertyTypeName)' in '\(typeName)'. Using nil as default.",
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column
          )
        }
        
        // Use nil as the default value when rendering fails
        childExpr = ExprSyntax(NilLiteralExprSyntax())
      }
      
      labeledArgs.append(
        LabeledExprSyntax(
          label: .identifier(propertyName),
          colon: .colonToken(),
          expression: childExpr
        )
      )
    }

    // Build proper FunctionCallExprSyntax with trailing commas added
    var argsWithCommas: [LabeledExprSyntax] = []
    for (index, arg) in labeledArgs.enumerated() {
      if index < labeledArgs.count - 1 {
        // Add comma for all but the last argument
        argsWithCommas.append(arg.with(\.trailingComma, .commaToken()))
      } else {
        argsWithCommas.append(arg)
      }
    }

    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: .identifier(typeName)),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax(argsWithCommas),
        rightParen: .rightParenToken()
      )
    )
  }
  
  /// Extract the wrapped value from a property wrapper if detected
  ///
  /// Property wrappers in Swift use a backing storage property that starts with "_".
  /// For example, `@State var name: String` becomes `_name: State<String>`.
  /// This function detects property wrappers and attempts to extract the wrapped value.
  ///
  /// - Parameters:
  ///   - label: The property label from Mirror reflection
  ///   - value: The property value from Mirror reflection
  ///
  /// - Returns: A tuple of (propertyName, propertyValue) where the name has the underscore
  ///   prefix removed if it was a property wrapper, and the value is the wrapped value if available
  static func extractPropertyWrapperValue(label: String, value: Any) -> (String, Any) {
    // Check if this looks like a property wrapper backing storage
    guard label.hasPrefix("_") else {
      return (label, value)
    }
    
    // Remove the underscore prefix to get the actual property name
    let propertyName = String(label.dropFirst())
    
    // Try to extract the wrapped value using reflection
    let wrappedValue = extractWrappedValueFromWrapper(value)
    
    return (propertyName, wrappedValue)
  }
  
  /// Helper function to extract wrapped value from a property wrapper
  ///
  /// This function uses Mirror reflection to inspect the property wrapper and extract
  /// the wrapped value. For most property wrappers, the actual value is stored in an
  /// internal storage property (often the first child in the Mirror).
  ///
  /// For property wrappers that use UnsafeMutablePointer (like @Published), this function
  /// attempts to dereference the pointer to access the actual wrapped value.
  ///
  /// - Parameter wrapper: The property wrapper instance
  /// - Returns: The wrapped value if found, otherwise nil as a safe fallback
  static func extractWrappedValueFromWrapper(_ wrapper: Any) -> Any {
    let mirror = Mirror(reflecting: wrapper)
    
    // Property wrappers typically have internal storage properties
    // Try to find the actual value by inspecting the mirror's children
    // For many property wrappers (like @State, @Published, etc.), the first child
    // contains the actual stored value
    if let firstChild = mirror.children.first {
      let childValue = firstChild.value
      let childTypeName = String(describing: type(of: childValue))
      
      // Check if the child is an unsafe pointer - try to dereference it
      if childTypeName.hasPrefix("Unsafe") && childTypeName.contains("Pointer") {
        // Try to dereference the pointer to get the wrapped value
        // This is common with @Published and other Combine property wrappers
        if let dereferencedValue = tryDereferencePointer(childValue) {
          return dereferencedValue
        }
        
        // If dereferencing fails, return nil as a safe fallback
        return Optional<Any>.none as Any
      }
      
      // Check if the child looks like internal Combine implementation
      // For @Published, we need to navigate: publisher -> subject -> currentValue
      if childTypeName.contains("Publisher") || childTypeName.contains("Subject") {
        // Try to extract currentValue from Combine publishers/subjects
        if let currentValue = extractCurrentValueFromPublisher(childValue) {
          return currentValue
        }
        
        // If we can't extract currentValue, return nil as a safe fallback
        return Optional<Any>.none as Any
      }
      
      // Check for other Combine infrastructure types that we can't extract from
      if childTypeName.contains("Subscriber") || childTypeName.contains("Subscription") {
        // These types don't have a currentValue we can extract
        return Optional<Any>.none as Any
      }
      
      // For regular types, return the child value for recursive rendering
      return childValue
    }
    
    // If no children found, we can't extract a value
    // Return nil as a safe fallback
    return Optional<Any>.none as Any
  }
  
  /// Extracts the current value from a Combine Publisher or Subject
  ///
  /// For @Published properties, the structure is:
  /// - publisher (first child of wrapper)
  ///   - subject (child of publisher)
  ///     - currentValue (child of subject) ← This is what we want
  ///
  /// - Parameter publisherOrSubject: The publisher or subject instance
  /// - Returns: The current value if found, nil otherwise
  static func extractCurrentValueFromPublisher(_ publisherOrSubject: Any) -> Any? {
    // Try to find currentValue directly in this level
    let mirror = Mirror(reflecting: publisherOrSubject)
    
    // Check if this level has a currentValue property
    for child in mirror.children {
      if child.label == "currentValue" {
        return child.value
      }
    }
    
    // If not found, navigate deeper through publisher/subject hierarchy
    // Look for: publisher -> subject -> currentValue
    for child in mirror.children {
      let childTypeName = String(describing: type(of: child.value))
      
      // Navigate through publisher or subject children
      if child.label == "publisher" || child.label == "subject" || 
         childTypeName.contains("Publisher") || childTypeName.contains("Subject") {
        
        // Recursively search for currentValue in this child
        if let currentValue = extractCurrentValueFromPublisher(child.value) {
          return currentValue
        }
      }
    }
    
    return nil
  }
  
  /// Attempts to dereference an UnsafeMutablePointer or UnsafePointer to access the pointee
  ///
  /// Since we don't know the generic type parameter at compile time, this function
  /// tries to cast to common types and dereference them.
  ///
  /// - Parameter pointer: The unsafe pointer (as Any)
  /// - Returns: The dereferenced value if successful, nil otherwise
  static func tryDereferencePointer(_ pointer: Any) -> Any? {
    // Try to dereference using _openExistential
    func attemptDeref<P>(_ ptr: P) -> Any? {
      // Try casting to known pointer types and dereference
      // Common types used in SwiftUI/Combine property wrappers
      
      // String
      if let stringPtr = ptr as? UnsafeMutablePointer<String> {
        return stringPtr.pointee
      }
      if let stringPtr = ptr as? UnsafePointer<String> {
        return stringPtr.pointee
      }
      
      // Int variants
      if let intPtr = ptr as? UnsafeMutablePointer<Int> {
        return intPtr.pointee
      }
      if let intPtr = ptr as? UnsafePointer<Int> {
        return intPtr.pointee
      }
      if let int8Ptr = ptr as? UnsafeMutablePointer<Int8> {
        return int8Ptr.pointee
      }
      if let int16Ptr = ptr as? UnsafeMutablePointer<Int16> {
        return int16Ptr.pointee
      }
      if let int32Ptr = ptr as? UnsafeMutablePointer<Int32> {
        return int32Ptr.pointee
      }
      if let int64Ptr = ptr as? UnsafeMutablePointer<Int64> {
        return int64Ptr.pointee
      }
      
      // UInt variants
      if let uintPtr = ptr as? UnsafeMutablePointer<UInt> {
        return uintPtr.pointee
      }
      if let uint8Ptr = ptr as? UnsafeMutablePointer<UInt8> {
        return uint8Ptr.pointee
      }
      if let uint16Ptr = ptr as? UnsafeMutablePointer<UInt16> {
        return uint16Ptr.pointee
      }
      if let uint32Ptr = ptr as? UnsafeMutablePointer<UInt32> {
        return uint32Ptr.pointee
      }
      if let uint64Ptr = ptr as? UnsafeMutablePointer<UInt64> {
        return uint64Ptr.pointee
      }
      
      // Bool
      if let boolPtr = ptr as? UnsafeMutablePointer<Bool> {
        return boolPtr.pointee
      }
      if let boolPtr = ptr as? UnsafePointer<Bool> {
        return boolPtr.pointee
      }
      
      // Double and Float
      if let doublePtr = ptr as? UnsafeMutablePointer<Double> {
        return doublePtr.pointee
      }
      if let floatPtr = ptr as? UnsafeMutablePointer<Float> {
        return floatPtr.pointee
      }
      
      // Character
      if let charPtr = ptr as? UnsafeMutablePointer<Character> {
        return charPtr.pointee
      }
      
      // Arrays (common in SwiftUI)
      if let arrayPtr = ptr as? UnsafeMutablePointer<[Any]> {
        return arrayPtr.pointee
      }
      
      // Dictionary
      if let dictPtr = ptr as? UnsafeMutablePointer<[AnyHashable: Any]> {
        return dictPtr.pointee
      }
      
      // Optional types
      if let optStringPtr = ptr as? UnsafeMutablePointer<String?> {
        return optStringPtr.pointee
      }
      if let optIntPtr = ptr as? UnsafeMutablePointer<Int?> {
        return optIntPtr.pointee
      }
      if let optBoolPtr = ptr as? UnsafeMutablePointer<Bool?> {
        return optBoolPtr.pointee
      }
      
      // If we can't dereference, return nil
      return nil
    }
    
    return _openExistential(pointer, do: attemptDeref)
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
    
    // Parse the string expression to proper ExprSyntax
    // The string should be valid Swift code generated by the macro
    let sourceFile = Parser.parse(source: exprString)
    
    // Extract the first expression from the parsed source
    if let firstStatement = sourceFile.statements.first,
       let exprStatement = firstStatement.item.as(ExpressionStmtSyntax.self) {
      return exprStatement.expression
    }
    
    // Fallback: if parsing fails, throw an error instead of silently returning nil
    let typeName = String(describing: type(of: exportable))
    reportIssue(
      "Failed to parse SwiftSnapshotExportable expression for type '\(typeName)'. Generated string was: '\(exprString)'",
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )
    throw SwiftSnapshotError.reflection(
      "SwiftSnapshotExportable parsing failed for type '\(typeName)'. Check macro-generated code.",
      path: context.path
    )
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
