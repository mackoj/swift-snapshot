# Architecture rules

The mechanical part of `AGENT.md`, enforced by the `Architecture/` package with [swift-llm-check](https://github.com/mackoj/swift-llm-check): `swift test --package-path Architecture` (macOS). Generated from its rules; do not edit by hand.

## engine

`SwiftLiteralReflection`: value in, `ExprSyntax` out. Read before you touch the renderer.

### `SwiftLiteralReflection` performs no I/O and reads no global, clock, logger or dependency.

`engine-reads-no-process-state`: The engine is value in, `ExprSyntax` out (AGENT.md, "No globals below the entry point"). Everything it needs arrives in a `RenderContext`, so the same value with the same context renders the same bytes whatever else the process is doing. `reportIssue` is a test failure, not a logger: it was once called on every render and failed the tests of anyone exporting a fixture.

**How to fix:** Add the setting to `RenderOptions` or the renderer to `ValueRenderers`, and read it from the context. Report a value that cannot be rendered by throwing a `LiteralError` that names the path.

Bad:

```swift
if LiteralConfig.renderOptions().sortDictionaryKeys { pairs.sort { $0.key < $1.key } }
reportIssue("Rendering \(typeName)")
```

Good:

```swift
if context.options.sortDictionaryKeys { pairs.sort { $0.key < $1.key } }
throw LiteralError.unsupportedType(typeName, path: context.path)
```

### `SwiftLiteralReflection` imports only Foundation, SwiftSyntax, SwiftParser and SwiftParserDiagnostics.

`engine-imports-stay-within-budget`: `SwiftLiteralReflection` is a product on its own, for anyone who wants expressions and not files. Every import is a dependency its users build. Configuration, swift-format and swift-dependencies belong to `SwiftLiteralCore`, which depends on the engine and never the other way round.

**How to fix:** Move the code that needs the module into `SwiftLiteralCore`, and pass what the engine needs through `RenderContext`.

Bad:

```swift
// Sources/SwiftLiteralReflection/ValueRenderer.swift
import SwiftFormat
```

Good:

```swift
// Sources/SwiftLiteralCore/CodeFormatter.swift
import SwiftFormat
```

### The library never writes `try?` or `try!`.

`errors-are-not-swallowed`: A wrong file that looks right is the failure this library exists to prevent (AGENT.md, "Errors, not silence"). `try?` turns a value that failed to render into `nil`, which renders as a fixture that compiles and is wrong. `try!` turns it into a crash in the caller's test run.

**How to fix:** Let the error propagate, or catch it and throw a `LiteralError` that names the type and the path.

Bad:

```swift
let rendered = (try? text(child.value, context: context)) ?? "nil"
```

Good:

```swift
let rendered = try text(child.value, context: context.appending(path: label))
```

## configuration

Global state and where it is read. Read before you add a setting or read one.

### Only `LiteralConfig.swift` and the live `LiteralConfigurationClient` read `LiteralConfig`.

`configuration-is-read-at-the-entry-point`: A render reads its configuration once, through the `literalConfiguration` dependency, at the top of `Literal.source` (AGENT.md, "No globals below the entry point"). A second read of the global further down ignores what a test scoped with `withDependencies`, so the test passes or fails depending on what another test set at the same moment.

**How to fix:** Read the setting from `@Dependency(\.literalConfiguration)` in `Literal`, and pass it down as a parameter. `LiteralConfig.libraryDefault…()` returns a constant and may be called anywhere.

Bad:

```swift
// Sources/SwiftLiteralCore/CodeFormatter.swift
if let configSource = LiteralConfig.getFormatConfigSource() {
```

Good:

```swift
// Sources/SwiftLiteralCore/Literal.swift
let configSource = configuration.formatConfigSource()
CodeFormatter.formatFile(…, configSource: configSource)
```

### `nonisolated(unsafe)` appears only in `LiteralConfig.swift`.

`global-state-lives-in-literal-config`: `LiteralConfig` is the one deliberate global, behind an `NSLock` (AGENT.md, "Fear singletons"). A renderer registry singleton was removed after it made a test pass five times locally and fail on the first CI run. Swift 6 rejects any other mutable global, so `nonisolated(unsafe)` is the only way to add one.

**How to fix:** Pass the state in: a `RenderContext` field in the engine, a `LiteralConfigurationClient` closure in Core. If it really is app-wide configuration, add it to `LiteralConfig`, behind its lock.

Bad:

```swift
nonisolated(unsafe) static var shared = ValueRenderers()
```

Good:

```swift
let expression = try ValueRenderer.render(value, context: RenderContext(renderers: renderers))
```

## api

Public signatures under Swift 6 strict concurrency. Read before you add a public closure.

### A closure in a public parameter or property is `@Sendable`.

`public-closures-are-sendable`: The package builds in the Swift 6 language mode (AGENT.md, "Swift 6 strict concurrency"). Renderers and configuration closures are stored and called from whichever task renders. A closure that is not `@Sendable` cannot be stored in a `Sendable` type, and adding the attribute later breaks every caller that captured something that is not.

**How to fix:** Mark the closure type `@Sendable`, after `@escaping` when it has one.

Bad:

```swift
public mutating func register<Value>(_ type: Value.Type, render: @escaping (Value) -> ExprSyntax)
```

Good:

```swift
public mutating func register<Value>(_ type: Value.Type, render: @escaping @Sendable (Value) -> ExprSyntax)
```

## testing

Swift Testing, isolated tests, nothing silenced. Read before you add, skip or scope a test.

### Tests use Swift Testing, never XCTest.

`tests-use-swift-testing`: The suite is Swift Testing only (AGENT.md, "Testing rules"): `@Test`, `@Suite`, `#expect`. Dependency overrides are scoped with Swift Testing traits, which XCTest has no equivalent for.

**How to fix:** Write an `@Suite` of `@Test` functions with `#expect` and `#require`, and `import Testing`.

Bad:

```swift
import XCTest
final class PerformanceTests: XCTestCase { func testLargeArray() { measure { … } } }
```

Good:

```swift
import Testing
@Suite struct RenderTests { @Test func largeArray() throws { #expect(…) } }
```

### Only the four suites that test the global pathway read the live configuration.

`live-configuration-stays-in-its-suites`: A test reads the `literalConfiguration` dependency, whose test value is the library defaults, so tests do not share state (AGENT.md, "Tests must not share state"). `EditorConfigIntegrationTests`, `FormattingConfigTests`, `LiteralConfigTests` and `SwiftLiteralTests` test `LiteralConfig` itself and opt back in. A fifth suite on the live globals is another suite whose result depends on what ran beside it.

**How to fix:** Scope the setting to the test with `withDependencies { $0.literalConfiguration.formatProfile = { … } }`. If the suite really tests `LiteralConfig`, add it to `Detect.liveConfigurationSuites` and say why in the PR.

Bad:

```swift
@Suite(.dependency(\.literalConfiguration, .live)) struct PathResolverTests {
```

Good:

```swift
withDependencies {
  $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
} operation: {
  try Literal.source(of: value, named: "fixture")
}
```

### `withKnownIssue` says what the issue is.

`known-issues-explain-themselves`: A known issue hides a failing expectation. Without a reason, the next reader cannot tell a bug waiting for a fix from a test nobody understood, and nobody removes it once the bug is fixed.

**How to fix:** Pass the reason as the first argument, with the GitHub issue that tracks it.

Bad:

```swift
withKnownIssue { try Literal.source(of: model, named: "fixture") }
```

Good:

```swift
withKnownIssue("@Published keeps its value where Mirror cannot reach it (mackoj/swift-snapshot#12)") {
  try Literal.source(of: model, named: "fixture")
}
```

### No test or suite is `.disabled`.

`tests-are-not-disabled`: A disabled test still reads as coverage while checking nothing. The suite was broken for months once and nothing said so (PLAN.md). A failing behaviour is fixed, or asserted as a known issue that names its tracking issue.

**How to fix:** Fix the code or the test. If the bug must wait, wrap the failing part in `withKnownIssue("…#N")`.

Bad:

```swift
@Test(.disabled("flaky")) func everySampleTypechecks() throws {
```

Good:

```swift
@Test func everySampleTypechecks() throws {
```
