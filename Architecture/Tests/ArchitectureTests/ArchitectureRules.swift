import LLMCheck
import Testing

/// The rules, run on the repository. A failure prints the rule, why it exists and how to fix it.
@Suite("Architecture rules")
struct ArchitectureRules {
  static func sources() throws -> Scope { try repository().productionCode.in("/Sources") }
  static func engine() throws -> Scope { try sources().in("Sources/SwiftLiteralReflection") }
  static func core() throws -> Scope { try sources().in("Sources/SwiftLiteralCore") }
  static func tests() throws -> Scope { try repository().testCode.in("/Tests") }

  @Test func engineReadsNoProcessState() throws {
    let engine = try Self.engine()
    #expect(engine.relativePaths.count > 3)
    expectNone(Detect.processState(in: engine), rule: .engineReadsNoProcessState)
  }

  @Test func engineImportsStayWithinBudget() throws {
    expectNone(Detect.engineImportsOverBudget(in: try Self.engine()), rule: .engineImportsStayWithinBudget)
  }

  @Test func errorsAreNotSwallowed() throws {
    let library = try Self.sources().excluding("SwiftLiteralMacros")
    expectNone(Detect.swallowedErrors(in: library), rule: .errorsAreNotSwallowed)
  }

  @Test func configurationIsReadAtTheEntryPoint() throws {
    let core = try Self.core()
    #expect(core.containing("LiteralConfig").relativePaths.count > 1)
    expectNone(Detect.globalConfigurationReads(in: core), rule: .configurationIsReadAtTheEntryPoint)
  }

  @Test func globalStateLivesInLiteralConfig() throws {
    expectNone(Detect.unsafeGlobalState(in: try Self.sources()), rule: .globalStateLivesInLiteralConfig)
  }

  @Test func publicClosuresAreSendable() throws {
    expectNone(Detect.nonSendablePublicClosures(in: try Self.sources()), rule: .publicClosuresAreSendable)
  }

  @Test func testsUseSwiftTesting() throws {
    let tests = try Self.tests()
    #expect(tests.containing("import Testing").relativePaths.count > 5)
    expectNone(Detect.xcTestImports(in: tests), rule: .testsUseSwiftTesting)
  }

  @Test func liveConfigurationStaysInItsSuites() throws {
    expectNone(
      Detect.liveConfigurationOutsideItsSuites(in: try Self.tests()), rule: .liveConfigurationStaysInItsSuites)
  }

  @Test func knownIssuesExplainThemselves() throws {
    expectNone(Detect.unexplainedKnownIssues(in: try Self.tests()), rule: .knownIssuesExplainThemselves)
  }

  @Test func testsAreNotDisabled() throws {
    expectNone(Detect.disabledTests(in: try Self.tests()), rule: .testsAreNotDisabled)
  }
}

/// Keeps `docs/architecture-rules.md` in step with the rules. Regenerate with
/// `LLM_CHECK_RECORD=1 swift test --package-path Architecture`.
@Test func rulesDocumentIsUpToDate() throws {
  let catalog = RuleCatalog(allRules)
  #expect(catalog.duplicateIDs.isEmpty)
  try expectFile(
    "docs/architecture-rules.md", in: repository(),
    matches: catalog.markdown(
      title: "Architecture rules",
      introduction: """
        The mechanical part of `AGENT.md`, enforced by the `Architecture/` package with \
        [swift-llm-check](https://github.com/mackoj/swift-llm-check): `swift test --package-path Architecture` \
        (macOS). Generated from its rules; do not edit by hand.
        """))
}
