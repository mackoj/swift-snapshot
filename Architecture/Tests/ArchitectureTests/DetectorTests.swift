import LLMCheck
import Testing

/// Each detector on snippets: it finds what its rule forbids and nothing its rule allows.
@Suite struct DetectorTests {
  func scope(_ source: String, at path: String = "Sources/SwiftLiteralReflection/File.swift") -> Scope {
    Scope(files: [SourceFile(path: path, source: source)])
  }

  @Test func processStateIsFound() {
    let found = Detect.processState(
      in: scope(
        """
        let files = FileManager.default
        let now = Date()
        let later = Date.now
        print("rendered")
        reportIssue("rendering")
        let options = LiteralConfig.renderOptions()
        @Dependency(\\.literalConfiguration) var configuration
        let root = ProcessInfo.processInfo.environment["SWIFT_SNAPSHOT_ROOT"]
        """))
    #expect(Set(found.map(\.location.line)) == [1, 2, 3, 4, 5, 6, 7, 8])
  }

  @Test func pureCodePasses() {
    let found = Detect.processState(
      in: scope(
        """
        // FileManager and LiteralConfig are fine in a comment.
        let message = "Register a renderer with LiteralConfig.registerRenderer"
        let epoch = Date(timeIntervalSince1970: 0)
        let sorted = context.options.sortDictionaryKeys
        stream.print(value)
        """))
    #expect(found.isEmpty)
  }

  @Test func engineImportsOverBudgetAreFound() {
    let found = Detect.engineImportsOverBudget(
      in: scope("import Foundation\nimport SwiftSyntax\nimport SwiftFormat\nimport Dependencies\nimport SwiftParser"))
    #expect(found.map(\.node.moduleName) == ["SwiftFormat", "Dependencies"])
  }

  @Test func globalConfigurationReadsAreFound() {
    let found = Detect.globalConfigurationReads(
      in: scope(
        """
        if let source = LiteralConfig.getFormatConfigSource() {}
        let profile = LiteralConfig.libraryDefaultFormatProfile()
        let header = LiteralConfig.getGlobalHeader()
        """, at: "Sources/SwiftLiteralCore/CodeFormatter.swift"))
    #expect(found.map(\.location.line) == [1, 3])
  }

  @Test func configurationReadersPass() {
    let source = "let options = LiteralConfig.renderOptions()"
    #expect(Detect.globalConfigurationReads(in: scope(source, at: "Sources/SwiftLiteralCore/LiteralConfig.swift")).isEmpty)
    #expect(
      Detect.globalConfigurationReads(
        in: scope(source, at: "Sources/SwiftLiteralCore/LiteralConfigurationClient.swift")
      ).isEmpty)
  }

  @Test func unsafeGlobalStateIsFound() {
    let source = """
      private nonisolated(unsafe) static var registry = ValueRenderers()
      nonisolated func render() {}
      """
    let found = Detect.unsafeGlobalState(in: scope(source, at: "Sources/SwiftLiteralCore/Registry.swift"))
    #expect(found.map(\.location.line) == [1])
    #expect(Detect.unsafeGlobalState(in: scope(source, at: "Sources/SwiftLiteralCore/LiteralConfig.swift")).isEmpty)
  }

  @Test func nonSendablePublicClosuresAreFound() {
    let found = Detect.nonSendablePublicClosures(
      in: scope(
        """
        public func register(render: @escaping (Int) -> String) {}
        public var header: () -> String?
        public init(transform: ((Int) -> Int)? = nil) {}
        func helper(body: () -> Void) {}
        public func register(sendable: @escaping @Sendable (Int) -> String) {}
        public var renderers: @Sendable () -> ValueRenderers
        public init(optional: (@Sendable (Int) -> Int)? = nil) {}
        public func render(_ value: Any, context: RenderContext) {}
        """))
    #expect(found.map(\.location.line) == [1, 3, 2])
  }

  @Test func uncommentedUncheckedSendableIsFound() {
    let found = Detect.uncommentedUncheckedSendable(
      in: scope(
        """
        final class Cache: @unchecked Sendable {}

        // Every access to `names` holds `lock`.
        final class Guarded: @unchecked Sendable {}
        extension Box: @unchecked Sendable {}  // Box is immutable after init.
        """))
    #expect(found.map(\.location.line) == [1])
  }

  @Test func swallowedErrorsAreFound() {
    let found = Detect.swallowedErrors(
      in: scope(
        """
        let a = try? render(value)
        let b = try! render(value)
        let c = try render(value)
        """))
    #expect(found.map(\.location.line) == [1, 2])
  }

  @Test func xcTestImportsAreFound() {
    let found = Detect.xcTestImports(in: scope("import XCTest\nimport Testing", at: "Tests/T/A.swift"))
    #expect(found.map(\.location.line) == [1])
  }

  @Test func liveConfigurationOutsideItsSuitesIsFound() {
    let source = """
      @Suite(.dependency(\\.literalConfiguration, .live)) struct A {}
      @Suite(.dependency(\\.literalConfiguration, .default)) struct B {}
      @Suite(.dependency(\\.date, .live)) struct C {}
      """
    let found = Detect.liveConfigurationOutsideItsSuites(
      in: scope(source, at: "Tests/SwiftLiteralTests/PathResolverTests.swift"))
    #expect(found.map(\.location.line) == [1])
    #expect(
      Detect.liveConfigurationOutsideItsSuites(
        in: scope(source, at: "Tests/SwiftLiteralTests/LiteralConfigTests.swift")
      ).isEmpty)
  }

  @Test func unexplainedKnownIssuesAreFound() {
    let found = Detect.unexplainedKnownIssues(
      in: scope(
        """
        withKnownIssue { try render() }
        withKnownIssue(isIntermittent: true) { try render() }
        withKnownIssue("@Published is opaque to Mirror (#12)") { try render() }
        """, at: "Tests/T/A.swift"))
    #expect(found.map(\.location.line) == [1, 2])
  }

  @Test func disabledTestsAreFound() {
    let found = Detect.disabledTests(
      in: scope(
        """
        @Test(.disabled("flaky")) func a() {}
        @Suite(.disabled()) struct B {}
        @Test func c() { rule.disabled() }
        """, at: "Tests/T/A.swift"))
    #expect(found.map(\.location.line) == [1, 2])
  }
}
