# swift-snapshot: rebuild plan

Working branch: `worktree-rebrand-and-tests`
Worktree: `.claude/worktrees/rebrand-and-tests`

Update the checkboxes as work lands. Anything checked is done and verified; do not redo it.

## Decisions taken (2026-08-19)

- Breaking changes allowed. 0.x, break freely.
- Tests must really typecheck the generated code, not just parse it.
- Reflection engine gets its own target.
- Name: keep the spirit, open to a rename. Candidates in P5.

## P0 — make `swift test` green (BLOCKER)

`swift test` on `main` segfaults. It has been red the whole time.

- [ ] Fix SIGSEGV in `targetLevelReflectionExtractionAppliesRedaction`
- [ ] `swift test` runs to completion

Root cause: `SwiftSnapshotRuntime.generateSwiftCode` reads `@Dependency(\.swiftSnapshotConfig)`.
Crash is inside swift-dependencies `CachedValues` -> swift-testing `_currentTest()` -> `outlined destroy of Test?`.
Only fires from the MacroTesting suite. Dependency/toolchain ABI mismatch.

Fix: delete the dependency. `SwiftSnapshotConfigClient` is 13 closures wrapping static
functions, and its `testValue` is `.live`, so it buys zero test isolation. It is pure
ceremony that happens to crash.

## P1 — split the reflection engine

- [ ] New target `SwiftSnapshotReflection`: value -> `ExprSyntax`. No file I/O, no global config.
- [ ] `SwiftSnapshotCore` keeps config, paths, formatting, file writing.
- [ ] New test target `SwiftSnapshotReflectionTests`.

## P2 — make the testing story real

- [ ] Round-trip typecheck harness: render values, emit one file, run `swiftc -typecheck` once.
- [ ] Reflection coverage matrix (see P3 for the bugs it should catch).

## P3 — fix what the tests expose

Found by reading, before writing a line of test:

- [ ] Dictionary keys are stringified. `[1: "a"]` renders `["1": "a"]`. Does not compile.
- [ ] `reportIssue` used as a logger. Any user exporting inside a test gets spurious failures.
- [ ] Render failures are swallowed and replaced with `nil`. Produces non-compiling output and calls it success.
- [ ] Enum case names come from `String(describing:)`. Wrong for `CustomStringConvertible` types.
- [ ] Generic `Collection` fallback emits `Type<...>([...])`. Wrong for ranges, string views, most collections.
- [ ] Nested optionals collapse.

## P4 — deprecate and isolate

- [ ] Delete the macro-expression-string path: `useMacroGeneratedExpressions`, `__swiftSnapshot_makeExpr`, `renderSwiftSnapshotExportable`. The source comments already admit it does not work.
- [ ] Delete `tryDereferencePointer` and `extractCurrentValueFromPublisher`. Hand-rolled pointer casts against Combine internals.
- [ ] Keep `__swiftSnapshot_reflectionFields`. That is the redaction path that works.

## P5 — docs and README

- [ ] Pick a name.
- [ ] Rewrite README.
- [ ] Rewrite DocC articles.

Name candidates, no "fixture":

| Name | Reads as |
|---|---|
| `SwiftLiteral` | turns a value into a Swift literal. Most literal, least clever. |
| `Petrify` | live value turned to stone. Memorable. |
| `Engrave` | engrave a runtime value into source. |
| `Reify` | precise, CS-flavoured, slightly academic. |
