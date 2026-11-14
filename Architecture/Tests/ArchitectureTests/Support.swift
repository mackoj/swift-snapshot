import LLMCheck

/// The swift-snapshot repository, rooted where `.llm-check.yaml` is. Its file list and every parsed file are shared
/// by all suites, which Swift Testing runs in parallel.
func repository() throws -> Codebase { try Codebase() }

extension RuleCategory {
  static let engine = RuleCategory(
    "engine",
    description: "`SwiftLiteralReflection`: value in, `ExprSyntax` out. Read before you touch the renderer."
  )
  static let configuration = RuleCategory(
    "configuration",
    description: "Global state and where it is read. Read before you add a setting or read one."
  )
  static let api = RuleCategory(
    "api",
    description: "Public signatures under Swift 6 strict concurrency. Read before you add a public closure."
  )
  static let testing = RuleCategory(
    "testing",
    description: "Swift Testing, isolated tests, nothing silenced. Read before you add, skip or scope a test."
  )
}
