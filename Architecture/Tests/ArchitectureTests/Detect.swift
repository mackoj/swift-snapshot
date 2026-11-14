import LLMCheck
import SwiftSyntax

/// The detectors, separate from the codebase so `DetectorTests` can run them on snippets.
enum Detect {
  /// Types whose every use is I/O, process state or the global configuration.
  static let processStateTypes: Set<String> = [
    "FileManager", "FileHandle", "ProcessInfo", "URLSession", "UserDefaults", "NotificationCenter", "Bundle",
    "DispatchQueue", "LiteralConfig", "Dependency", "DependencyValues",
  ]

  /// Uses of I/O, a clock, a logger, the global configuration or a dependency: `FileManager.default`, `Date()`,
  /// `print(x)`, `reportIssue(x)`, `LiteralConfig.renderOptions()`, `@Dependency(…)`.
  static func processState(in scope: Scope) -> [Match<Syntax>] {
    let calls = scope.calls(named: "Date", "print", "reportIssue").filter { call in
      call.node.calledExpression.is(DeclReferenceExprSyntax.self)
        && (call.node.calledName != "Date" || call.node.arguments.isEmpty)
    }
    let now = scope.containing("Date.now").nodes(of: MemberAccessExprSyntax.self) {
      $0.node.declName.baseName.text == "now" && $0.node.base?.trimmedDescription == "Date"
    }
    let attributes = scope.containing("@Dependency").nodes(of: AttributeSyntax.self) {
      $0.node.attributeName.trimmedDescription == "Dependency"
    }
    return scope.references(to: processStateTypes) + calls.map(\.erased) + now.map(\.erased)
      + attributes.map(\.erased)
  }

  /// What `SwiftLiteralReflection` may import.
  static let engineModules: Set<String> = ["Foundation", "SwiftSyntax", "SwiftParser", "SwiftParserDiagnostics"]

  /// Imports in the engine outside its budget.
  static func engineImportsOverBudget(in scope: Scope) -> [Match<ImportDeclSyntax>] {
    scope.imports.filter { !engineModules.contains($0.node.moduleName) }
  }

  /// The files that may read `LiteralConfig`: the holder itself and the live dependency that wraps it.
  static let configurationReaders: Set<String> = ["LiteralConfig.swift", "LiteralConfigurationClient.swift"]

  /// `LiteralConfig` read anywhere but its own file and the live dependency. `libraryDefault…` members return
  /// constants, so they pass.
  static func globalConfigurationReads(in scope: Scope) -> [Match<Syntax>] {
    scope.references(to: "LiteralConfig").filter { match in
      guard !configurationReaders.contains(match.file.fileName) else { return false }
      let member = match.node.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.text
      return !(member?.hasPrefix("libraryDefault") ?? false)
    }
  }

  /// The one file that may hold mutable global state.
  static let globalStateHolder = "LiteralConfig.swift"

  /// `nonisolated(unsafe)` outside `LiteralConfig.swift`. Swift 6 rejects any other mutable global, so this is the
  /// only way to write one.
  static func unsafeGlobalState(in scope: Scope) -> [Match<DeclModifierSyntax>] {
    scope.containing("nonisolated(unsafe)").nodes(of: DeclModifierSyntax.self) {
      $0.node.name.tokenKind == .keyword(.nonisolated) && $0.node.detail?.detail.text == "unsafe"
        && $0.file.fileName != globalStateHolder
    }
  }

  /// Closure types in a public parameter or a public property that are not `@Sendable`.
  static func nonSendablePublicClosures(in scope: Scope) -> [Match<TypeSyntax>] {
    let parameters = scope.nodes(of: FunctionParameterSyntax.self) { isPublic(enclosingDeclaration(of: $0.node)) }
      .map { Match(node: $0.node.type, file: $0.file) }
    let properties = scope.nodes(of: VariableDeclSyntax.self) { isPublic(Syntax($0.node)) }
      .flatMap { match in
        match.node.bindings.compactMap(\.typeAnnotation?.type).map { Match(node: $0, file: match.file) }
      }
    return (parameters + properties).filter { $0.node.closureType != nil && !$0.node.hasAttribute("Sendable") }
  }

  private static func enclosingDeclaration(of parameter: FunctionParameterSyntax) -> Syntax? {
    sequence(first: Syntax(parameter), next: \.parent).first {
      $0.is(FunctionDeclSyntax.self) || $0.is(InitializerDeclSyntax.self) || $0.is(SubscriptDeclSyntax.self)
    }
  }

  private static func isPublic(_ declaration: Syntax?) -> Bool {
    guard let modifiers = declaration?.asProtocol(WithModifiersSyntax.self)?.modifiers else { return false }
    return modifiers.contains { ["public", "open"].contains($0.name.text) }
  }

  /// The suites that test the global pathway itself, and so read `LiteralConfig` through the live dependency.
  static let liveConfigurationSuites: Set<String> = [
    "EditorConfigIntegrationTests.swift", "FormattingConfigTests.swift", "LiteralConfigTests.swift",
    "SwiftLiteralTests.swift",
  ]

  /// `.dependency(\.literalConfiguration, .live)` outside the four suites that test the global pathway.
  static func liveConfigurationOutsideItsSuites(in scope: Scope) -> [Match<FunctionCallExprSyntax>] {
    scope.containing("literalConfiguration").calls(named: "dependency").filter { call in
      let arguments = call.node.arguments.map(\.expression.trimmedDescription)
      return arguments.count == 2 && arguments[0].hasSuffix(".literalConfiguration") && arguments[1] == ".live"
        && !liveConfigurationSuites.contains(call.file.fileName)
    }
  }
}
