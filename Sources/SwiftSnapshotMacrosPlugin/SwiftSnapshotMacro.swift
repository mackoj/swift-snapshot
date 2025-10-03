import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Main macro that generates snapshot metadata and helper methods.
public struct SwiftSnapshotMacro: MemberMacro, ExtensionMacro {
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

    // Generate __swiftSnapshot_folder if folder argument provided
    if let folder = arguments.folder {
      members.append(
        """
        internal static let __swiftSnapshot_folder: String? = \(literal: folder)
        """
      )
    } else {
      members.append(
        """
        internal static let __swiftSnapshot_folder: String? = nil
        """
      )
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
      extension \(raw: typeName): SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          #if DEBUG
          let defaultVarName = "\(raw: typeName.prefix(1).lowercased() + typeName.dropFirst())"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
            fileID: fileID,
            filePath: filePath
          )
          #else
          return URL(fileURLWithPath: "/tmp/swift-snapshot-noop")
          #endif
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

extension SwiftSnapshotMacro {
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

          if attrName == "SnapshotIgnore" {
            isIgnored = true
          } else if attrName == "SnapshotRename" {
            renamedTo = extractRenameArgument(from: attr)
          } else if attrName == "SnapshotRedact" {
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

    var mask: String?
    var hash = false

    for argument in arguments {
      guard let label = argument.label?.text else { continue }

      if label == "mask" {
        mask = extractStringLiteral(from: argument.expression)
      } else if label == "hash" {
        if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
          hash = boolLiteral.literal.text == "true"
        }
      }
    }

    // Validate mutually exclusive options
    let activeCount = [mask != nil, hash].filter { $0 }.count
    if activeCount > 1 {
      context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroDiagnostic.conflictingRedactionModes
        ))
      return nil
    }

    if hash {
      return RedactionInfo(mode: .hash)
    } else if let maskValue = mask {
      return RedactionInfo(mode: .mask(maskValue))
    } else {
      return RedactionInfo(mode: .mask("•••"))
    }
  }

  static func generatePropertyMetadataStruct() -> DeclSyntax {
    """
    internal struct __SwiftSnapshot_PropertyMetadata {
      let original: String
      let renamed: String?
      let redaction: __SwiftSnapshot_Redaction?
      let ignored: Bool
    }
    """
  }

  static func generateRedactionEnum() -> DeclSyntax {
    """
    internal enum __SwiftSnapshot_Redaction {
      case mask(String)
      case hash
    }
    """
  }

  static func generatePropertiesArray(properties: [PropertyInfo]) -> DeclSyntax {
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
      internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
        \(raw: propertyElements)
      ]
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

    // Build initializer arguments for non-ignored properties
    let activeProperties = properties.filter { !$0.isIgnored }

    // Build the arguments string
    var argumentParts: [String] = []
    for prop in activeProperties {
      let label = prop.renamedTo ?? prop.name

      if let redaction = prop.redaction {
        switch redaction.mode {
        case .mask(let maskValue):
          // Generate masked literal - need to escape quotes in the mask value
          argumentParts.append("\(label): \\\"\(maskValue)\\\"")
        case .hash:
          argumentParts.append("\(label): \\\"<hashed>\\\"")
        }
      } else {
        // Reference the actual property value via interpolation
        argumentParts.append("\(label): \\(instance.\(prop.name))")
      }
    }

    let arguments = argumentParts.joined(separator: ", ")

    return """
      internal static func __swiftSnapshot_makeExpr(from instance: Self) -> String {
        return "\(raw: typeName)(\(raw: arguments))"
      }
      """
  }

  static func generateEnumExpressionBuilder(
    from declaration: some DeclGroupSyntax,
    properties: [PropertyInfo],
    context: some MacroExpansionContext
  ) throws -> DeclSyntax {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw MacroError.notAnEnum
    }

    // Collect all enum cases
    var cases: [String] = []
    for member in enumDecl.memberBlock.members {
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

      for element in caseDecl.elements {
        let caseName = element.name.text

        if let associatedValue = element.parameterClause {
          // Case with associated values
          let parameters = associatedValue.parameters
          let bindings = parameters.enumerated().map { index, param in
            if let firstName = param.firstName?.text, firstName != "_" {
              return "let \(firstName)"
            } else {
              return "let val\(index)"
            }
          }.joined(separator: ", ")

          let arguments = parameters.enumerated().map { index, param in
            let valueName: String
            if let firstName = param.firstName?.text, firstName != "_" {
              valueName = firstName
            } else {
              valueName = "val\(index)"
            }

            let label: String
            if let firstName = param.firstName?.text, firstName != "_" {
              label = "\(firstName): "
            } else if let secondName = param.secondName?.text {
              label = "\(secondName): "
            } else {
              label = ""
            }

            return "\(label)\\(\(valueName))"
          }.joined(separator: ", ")

          cases.append(
            """
            case .\(caseName)(\(bindings)):
                  return ".\(caseName)(\(arguments))"
            """)
        } else {
          // Simple case without associated values
          cases.append(
            """
            case .\(caseName):
                  return ".\(caseName)"
            """)
        }
      }
    }

    let switchBody = cases.joined(separator: "\n      ")

    return """
      internal static func __swiftSnapshot_makeExpr(from instance: Self) -> String {
        switch instance {
        \(raw: switchBody)
        }
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
      return "@SwiftSnapshot applied to non-enum type but enum handling was requested"
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
    MessageID(domain: "SwiftSnapshotMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .conflictingRedactionModes:
      return .error
    }
  }
}
