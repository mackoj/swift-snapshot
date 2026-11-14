import LLMCheck

extension Rule {
  static let engineReadsNoProcessState = Rule(
    id: "engine-reads-no-process-state",
    title: "`SwiftLiteralReflection` performs no I/O and reads no global, clock, logger or dependency.",
    category: .engine,
    rationale: """
      The engine is value in, `ExprSyntax` out (AGENT.md, "No globals below the entry point"). Everything it needs \
      arrives in a `RenderContext`, so the same value with the same context renders the same bytes whatever else \
      the process is doing. `reportIssue` is a test failure, not a logger: it was once called on every render and \
      failed the tests of anyone exporting a fixture.
      """,
    howToFix: """
      Add the setting to `RenderOptions` or the renderer to `ValueRenderers`, and read it from the context. Report \
      a value that cannot be rendered by throwing a `LiteralError` that names the path.
      """,
    badExample: """
      if LiteralConfig.renderOptions().sortDictionaryKeys { pairs.sort { $0.key < $1.key } }
      reportIssue("Rendering \\(typeName)")
      """,
    goodExample: """
      if context.options.sortDictionaryKeys { pairs.sort { $0.key < $1.key } }
      throw LiteralError.unsupportedType(typeName, path: context.path)
      """
  )

  static let engineImportsStayWithinBudget = Rule(
    id: "engine-imports-stay-within-budget",
    title: "`SwiftLiteralReflection` imports only Foundation, SwiftSyntax, SwiftParser and SwiftParserDiagnostics.",
    category: .engine,
    rationale: """
      `SwiftLiteralReflection` is a product on its own, for anyone who wants expressions and not files. Every \
      import is a dependency its users build. Configuration, swift-format and swift-dependencies belong to \
      `SwiftLiteralCore`, which depends on the engine and never the other way round.
      """,
    howToFix: """
      Move the code that needs the module into `SwiftLiteralCore`, and pass what the engine needs through \
      `RenderContext`.
      """,
    badExample: """
      // Sources/SwiftLiteralReflection/ValueRenderer.swift
      import SwiftFormat
      """,
    goodExample: """
      // Sources/SwiftLiteralCore/CodeFormatter.swift
      import SwiftFormat
      """
  )

  static let configurationIsReadAtTheEntryPoint = Rule(
    id: "configuration-is-read-at-the-entry-point",
    title: "Only `LiteralConfig.swift` and the live `LiteralConfigurationClient` read `LiteralConfig`.",
    category: .configuration,
    rationale: """
      A render reads its configuration once, through the `literalConfiguration` dependency, at the top of \
      `Literal.source` (AGENT.md, "No globals below the entry point"). A second read of the global further down \
      ignores what a test scoped with `withDependencies`, so the test passes or fails depending on what another \
      test set at the same moment.
      """,
    howToFix: """
      Read the setting from `@Dependency(\\.literalConfiguration)` in `Literal`, and pass it down as a parameter. \
      `LiteralConfig.libraryDefault…()` returns a constant and may be called anywhere.
      """,
    badExample: """
      // Sources/SwiftLiteralCore/CodeFormatter.swift
      if let configSource = LiteralConfig.getFormatConfigSource() {
      """,
    goodExample: """
      // Sources/SwiftLiteralCore/Literal.swift
      let configSource = configuration.formatConfigSource()
      CodeFormatter.formatFile(…, configSource: configSource)
      """
  )

  static let globalStateLivesInLiteralConfig = Rule(
    id: "global-state-lives-in-literal-config",
    title: "`nonisolated(unsafe)` appears only in `LiteralConfig.swift`.",
    category: .configuration,
    rationale: """
      `LiteralConfig` is the one deliberate global, behind an `NSLock` (AGENT.md, "Fear singletons"). A renderer \
      registry singleton was removed after it made a test pass five times locally and fail on the first CI run. \
      Swift 6 rejects any other mutable global, so `nonisolated(unsafe)` is the only way to add one.
      """,
    howToFix: """
      Pass the state in: a `RenderContext` field in the engine, a `LiteralConfigurationClient` closure in Core. If \
      it really is app-wide configuration, add it to `LiteralConfig`, behind its lock.
      """,
    badExample: "nonisolated(unsafe) static var shared = ValueRenderers()",
    goodExample: "let expression = try ValueRenderer.render(value, context: RenderContext(renderers: renderers))"
  )

  static let publicClosuresAreSendable = Rule(
    id: "public-closures-are-sendable",
    title: "A closure in a public parameter or property is `@Sendable`.",
    category: .api,
    rationale: """
      The package builds in the Swift 6 language mode (AGENT.md, "Swift 6 strict concurrency"). Renderers and \
      configuration closures are stored and called from whichever task renders. A closure that is not \
      `@Sendable` cannot be stored in a `Sendable` type, and adding the attribute later breaks every caller \
      that captured something that is not.
      """,
    howToFix: "Mark the closure type `@Sendable`, after `@escaping` when it has one.",
    badExample: "public mutating func register<Value>(_ type: Value.Type, render: @escaping (Value) -> ExprSyntax)",
    goodExample:
      "public mutating func register<Value>(_ type: Value.Type, render: @escaping @Sendable (Value) -> ExprSyntax)"
  )

  static let errorsAreNotSwallowed = Rule(
    id: "errors-are-not-swallowed",
    title: "The library never writes `try?` or `try!`.",
    category: .engine,
    rationale: """
      A wrong file that looks right is the failure this library exists to prevent (AGENT.md, "Errors, not \
      silence"). `try?` turns a value that failed to render into `nil`, which renders as a fixture that compiles \
      and is wrong. `try!` turns it into a crash in the caller's test run.
      """,
    howToFix: """
      Let the error propagate, or catch it and throw a `LiteralError` that names the type and the path.
      """,
    badExample: "let rendered = (try? text(child.value, context: context)) ?? \"nil\"",
    goodExample: "let rendered = try text(child.value, context: context.appending(path: label))"
  )

  static let testsUseSwiftTesting = Rule(
    id: "tests-use-swift-testing",
    title: "Tests use Swift Testing, never XCTest.",
    category: .testing,
    rationale: """
      The suite is Swift Testing only (AGENT.md, "Testing rules"): `@Test`, `@Suite`, `#expect`. Dependency \
      overrides are scoped with Swift Testing traits, which XCTest has no equivalent for.
      """,
    howToFix: "Write an `@Suite` of `@Test` functions with `#expect` and `#require`, and `import Testing`.",
    badExample: """
      import XCTest
      final class PerformanceTests: XCTestCase { func testLargeArray() { measure { … } } }
      """,
    goodExample: """
      import Testing
      @Suite struct RenderTests { @Test func largeArray() throws { #expect(…) } }
      """
  )

  static let liveConfigurationStaysInItsSuites = Rule(
    id: "live-configuration-stays-in-its-suites",
    title: "Only the four suites that test the global pathway read the live configuration.",
    category: .testing,
    rationale: """
      A test reads the `literalConfiguration` dependency, whose test value is the library defaults, so tests do \
      not share state (AGENT.md, "Tests must not share state"). `EditorConfigIntegrationTests`, \
      `FormattingConfigTests`, `LiteralConfigTests` and `SwiftLiteralTests` test `LiteralConfig` itself and opt \
      back in. A fifth suite on the live globals is another suite whose result depends on what ran beside it.
      """,
    howToFix: """
      Scope the setting to the test with `withDependencies { $0.literalConfiguration.formatProfile = { … } }`. If \
      the suite really tests `LiteralConfig`, add it to `Detect.liveConfigurationSuites` and say why in the PR.
      """,
    badExample: "@Suite(.dependency(\\.literalConfiguration, .live)) struct PathResolverTests {",
    goodExample: """
      withDependencies {
        $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
      } operation: {
        try Literal.source(of: value, named: "fixture")
      }
      """
  )

  static let knownIssuesExplainThemselves = Rule(
    id: "known-issues-explain-themselves",
    title: "`withKnownIssue` says what the issue is.",
    category: .testing,
    rationale: """
      A known issue hides a failing expectation. Without a reason, the next reader cannot tell a bug waiting for a \
      fix from a test nobody understood, and nobody removes it once the bug is fixed.
      """,
    howToFix: "Pass the reason as the first argument, with the GitHub issue that tracks it.",
    badExample: "withKnownIssue { try Literal.source(of: model, named: \"fixture\") }",
    goodExample: """
      withKnownIssue("@Published keeps its value where Mirror cannot reach it (mackoj/swift-snapshot#12)") {
        try Literal.source(of: model, named: "fixture")
      }
      """
  )

  static let testsAreNotDisabled = Rule(
    id: "tests-are-not-disabled",
    title: "No test or suite is `.disabled`.",
    category: .testing,
    rationale: """
      A disabled test still reads as coverage while checking nothing. The suite was broken for months once and \
      nothing said so (PLAN.md). A failing behaviour is fixed, or asserted as a known issue that names its \
      tracking issue.
      """,
    howToFix: "Fix the code or the test. If the bug must wait, wrap the failing part in `withKnownIssue(\"…#N\")`.",
    badExample: "@Test(.disabled(\"flaky\")) func everySampleTypechecks() throws {",
    goodExample: "@Test func everySampleTypechecks() throws {"
  )
}

/// Every rule, in the order `docs/architecture-rules.md` lists them.
let allRules: [Rule] = [
  .engineReadsNoProcessState, .engineImportsStayWithinBudget, .errorsAreNotSwallowed,
  .configurationIsReadAtTheEntryPoint, .globalStateLivesInLiteralConfig, .publicClosuresAreSendable,
  .testsUseSwiftTesting, .liveConfigurationStaysInItsSuites, .knownIssuesExplainThemselves, .testsAreNotDisabled,
]
