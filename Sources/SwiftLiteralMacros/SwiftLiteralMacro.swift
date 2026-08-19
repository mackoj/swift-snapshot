import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Main macro that generates snapshot metadata and helper methods.
public struct SwiftLiteralMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Extract macro arguments
    let arguments = extractArguments(from: node)

    // Determine if this is a struct or enum
    let isEnum = declaration.is(EnumDeclSyntax.self)

    // Collect property metadata
    let properties = collectProperties(from: declaration, context: context)

    var members: [DeclSyntax] = []

    // Generate __swiftLiteral_folder if folder argument provided
    // Use computed properties for all types (works for both generic and non-generic)
    if let folder = arguments.folder {
      members.append("internal static var __swiftLiteral_folder: String? { \(literal: folder) }")
    } else {
      members.append("internal static var __swiftLiteral_folder: String? { nil }")
    }

    // Generate supporting types
    members.append(generatePropertyMetadataStruct())
    members.append(generateRedactionEnum())

    // Generate property metadata array
    members.append(generatePropertiesArray(properties: properties))

    // Generate expression builder
    if isEnum {
      members.append(
        try generateEnumExpressionBuilder(
          from: declaration, properties: properties, context: context))
    } else {
      members.append(
        try generateStructExpressionBuilder(
          from: declaration, properties: properties, context: context))
    }

    return members
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // Extract macro arguments
    let typeName = type.trimmedDescription

    // Generate export convenience method
    let extensionDecl: DeclSyntax =
      """
      extension \(raw: typeName): LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "\(raw: typeName.prefix(1).lowercased() + typeName.dropFirst())",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """

    guard let extensionDecl = extensionDecl.as(ExtensionDeclSyntax.self) else {
      return []
    }

    return [extensionDecl]
  }
}

// MARK: - Helper Methods

extension SwiftLiteralMacro {
  struct MacroArguments {
    var folder: String?
  }

  static func extractArguments(from node: AttributeSyntax) -> MacroArguments {
    var args = MacroArguments()

    guard case .argumentList(let arguments) = node.arguments else {
      return args
    }

    for argument in arguments {
      guard let label = argument.label?.text else { continue }

      if label == "folder" {
        args.folder = extractStringLiteral(from: argument.expression)
      }
    }

    return args
  }

  static func extractStringLiteral(from expr: ExprSyntax) -> String? {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
      return stringLiteral.segments.trimmedDescription
    }
    return nil
  }

  static func collectProperties(
    from declaration: some DeclGroupSyntax, context: some MacroExpansionContext
  ) -> [PropertyInfo] {
    let members = declaration.memberBlock.members
    var properties: [PropertyInfo] = []

    for member in members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

      // Only process stored properties (let or var with no body)
      guard varDecl.bindings.first?.accessorBlock == nil else { continue }

      for binding in varDecl.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

        let propertyName = pattern.identifier.text

        // Check for property attributes
        var isIgnored = false
        var renamedTo: String?
        var redaction: RedactionInfo?

        for attribute in varDecl.attributes {
          guard case .attribute(let attr) = attribute else { continue }
          guard let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self) else {
            continue
          }
          let attrName = identifierType.name.text

          if attrName == "LiteralIgnore" {
            isIgnored = true
          } else if attrName == "LiteralRename" {
            renamedTo = extractRenameArgument(from: attr)
          } else if attrName == "LiteralRedact" {
            redaction = extractRedactionArguments(from: attr, context: context)
          }
        }

        properties.append(
          PropertyInfo(
            name: propertyName,
            renamedTo: renamedTo,
            isIgnored: isIgnored,
            redaction: redaction,
            type: binding.typeAnnotation?.type.trimmedDescription
          ))
      }
    }

    return properties
  }

  static func extractRenameArgument(from attribute: AttributeSyntax) -> String? {
    guard case .argumentList(let arguments) = attribute.arguments,
      let firstArg = arguments.first
    else {
      return nil
    }
    return extractStringLiteral(from: firstArg.expression)
  }

  static func extractRedactionArguments(
    from attribute: AttributeSyntax, context: some MacroExpansionContext
  ) -> RedactionInfo? {
    guard case .argumentList(let arguments) = attribute.arguments else {
      return RedactionInfo(mode: .mask("•••"))
    }

    // The first argument should be the RedactionStyle enum
    guard let firstArg = arguments.first else {
      return RedactionInfo(mode: .mask("•••"))
    }

    // Parse the enum case expression: .mask("...") or .hash
    if let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self) {
      let caseName = memberAccess.declName.baseName.text

      if caseName == "hash" {
        return RedactionInfo(mode: .hash)
      } else if caseName == "mask" {
        // For .mask("value"), we need to look for a function call with the string argument
        return RedactionInfo(mode: .mask("•••"))
      }
    } else if let functionCall = firstArg.expression.as(FunctionCallExprSyntax.self) {
      // Handle .mask("value") case
      if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self) {
        let caseName = memberAccess.declName.baseName.text
        if caseName == "mask" {
          // Extract the string argument
          if let stringArg = functionCall.arguments.first?.expression,
            let stringLiteral = extractStringLiteral(from: stringArg)
          {
            return RedactionInfo(mode: .mask(stringLiteral))
          }
        }
      }
    }

    // Default fallback
    return RedactionInfo(mode: .mask("•••"))
  }

  static func generatePropertyMetadataStruct() -> DeclSyntax {
    """
    internal struct __SwiftLiteral_PropertyMetadata {
      let original: String
      let renamed: String?
      let redaction: __SwiftLiteral_Redaction?
      let ignored: Bool
    }
    """
  }

  static func generateRedactionEnum() -> DeclSyntax {
    """
    internal enum __SwiftLiteral_Redaction {
      case mask(String)
      case hash
    }
    """
  }

  static func generatePropertiesArray(properties: [PropertyInfo]) -> DeclSyntax {
    // Use computed properties for all types (works for both generic and non-generic)
    let propertyElements = properties.enumerated().map { index, prop -> String in
      let renamedStr = prop.renamedTo.map { "\"\($0)\"" } ?? "nil"
      let redactionStr =
        prop.redaction.map { redaction -> String in
          switch redaction.mode {
          case .mask(let value):
            return ".mask(\"\(value)\")"
          case .hash:
            return ".hash"
          }
        } ?? "nil"

      let indent = index == 0 ? "" : "    "
      return
        "\(indent).init(original: \"\(prop.name)\", renamed: \(renamedStr), redaction: \(redactionStr), ignored: \(prop.isIgnored))"
    }.joined(separator: ",\n")

    return """
      internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
        [
          \(raw: propertyElements)
        ]
      }
      """
  }

  static func generateStructExpressionBuilder(
    from declaration: some DeclGroupSyntax,
    properties: [PropertyInfo],
    context: some MacroExpansionContext
  ) throws -> DeclSyntax {
    // Get type name
    let typeName: String
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      typeName = structDecl.name.text
    } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
      typeName = classDecl.name.text
    } else {
      typeName = "Self"
    }

    _ = typeName

    // `@LiteralIgnore` drops the property. `@LiteralRename` changes the argument
    // label. `@LiteralRedact` replaces the value with a literal stand-in. All three
    // are source facts, invisible to reflection, so the macro hands them over here.
    let reflectionFields = properties.filter { !$0.isIgnored }.map { prop -> String in
      let label = prop.renamedTo ?? prop.name
      if let redaction = prop.redaction {
        switch redaction.mode {
        case .mask(let maskValue):
          return "LiteralField(label: \"\(label)\", value: \"\(maskValue)\")"
        case .hash:
          return "LiteralField(label: \"\(label)\", value: \"<hashed>\")"
        }
      }
      return "LiteralField(label: \"\(label)\", value: self.\(prop.name))"
    }.joined(separator: ", ")

    return """
      public func __swiftLiteral_fields() -> [LiteralField] {
        [
          \(raw: reflectionFields)
        ]
      }
      """
  }

  /// Enums render through reflection.
  ///
  /// Case names, labels, and payloads all survive `Mirror`, so there is nothing here the
  /// macro needs to describe. Returning no fields tells the renderer to reflect.
  static func generateEnumExpressionBuilder(
    from declaration: some DeclGroupSyntax,
    properties: [PropertyInfo],
    context: some MacroExpansionContext
  ) throws -> DeclSyntax {
    guard declaration.is(EnumDeclSyntax.self) else {
      throw MacroError.notAnEnum
    }

    return """
      public func __swiftLiteral_fields() -> [LiteralField] {
        []
      }
      """
  }
}

// MARK: - Supporting Types

struct PropertyInfo {
  let name: String
  let renamedTo: String?
  let isIgnored: Bool
  let redaction: RedactionInfo?
  let type: String?
}

struct RedactionInfo {
  enum Mode: Equatable {
    case mask(String)
    case hash
  }
  let mode: Mode
}

enum MacroError: Error, CustomStringConvertible {
  case notAnEnum

  var description: String {
    switch self {
    case .notAnEnum:
      return "@SwiftLiteral applied to non-enum type but enum handling was requested"
    }
  }
}

enum MacroDiagnostic: String, DiagnosticMessage {
  case conflictingRedactionModes

  var message: String {
    switch self {
    case .conflictingRedactionModes:
      return "Only one redaction mode (mask, hash, or remove) can be specified at a time"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "SwiftLiteralMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .conflictingRedactionModes:
      return .error
    }
  }
}
