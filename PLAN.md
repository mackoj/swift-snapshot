# swift-snapshot: rebuild plan

Working branch: `rework/tests-reflection-docs` (PR #49)

Checked items are done and verified. Do not redo them. What happened is in PROGRESS.md.

## Decisions taken (2026-08-19)

- Breaking changes allowed. 0.x, break freely.
- Tests must really typecheck the generated code, not just parse it.
- Reflection engine gets its own target.
- Name: open to a rename. Candidates below, waiting on a pick.

## P0 — make `swift test` green

- [x] Fix the SIGSEGV. Cause: `xctest-dynamic-overlay` 1.7.0 against the 6.3.3 toolchain.
- [x] Pin swift-snapshot-testing below 1.19, which does not compile on this toolchain.
- [x] `swift test` runs to completion. 197 tests pass.

## P1 — split the reflection engine

- [x] `SwiftLiteralReflection`: value -> `ExprSyntax`. No file I/O, no global config.
- [x] `SwiftLiteralCore` keeps config, paths, formatting, file writing.
- [x] `SwiftLiteralReflectionTests`.

## P2 — make the testing story real

- [x] Round-trip typecheck: render the matrix, emit one file, `swiftc -typecheck` once.
- [x] Pin the generated text as a snapshot so rendering changes show up in a diff.
- [x] Reflection coverage matrix.

## P3 — fix what the tests exposed

- [x] Dictionary keys were stringified.
- [x] `reportIssue` was used as a logger.
- [x] Render failures were swallowed and replaced with `nil`.
- [x] Enum case names came from `String(describing:)`.
- [x] Enum payload tuples were passed as a single argument.
- [x] Ranges rendered an initializer that does not exist.
- [x] Nested optionals collapsed.
- [x] Redaction applied only at the top level.
- [x] `@LiteralRename` was ignored on the reflection path.
- [x] `indent(level:)` ignored tab style.

## P4 — deprecate and isolate

- [x] Delete the macro-expression-string path.
- [x] Delete pointer dereferencing and Combine internals walking.
- [x] Delete `SwiftLiteralBootstrap`, which did nothing.
- [x] Keep `__swiftLiteral_fields`. That is the path that works.

## P5 — docs and README

- [ ] Pick a name.
- [ ] Rewrite README.
- [ ] Rewrite the DocC articles. Several describe things that no longer exist:
      `SwiftLiteralVsDebugSnapshots`, `StabilityAndSupportTiers`, `Architecture`
      (documents the dependency injection that is gone).
- [ ] Delete `EditorConfigVerification.md` and `EditorConfigMapping.md` or fold them into
      one formatting article.

Name candidates, no "fixture":

| Name | Reads as |
|---|---|
| `SwiftLiteral` | turns a value into a Swift literal. Most literal, least clever. |
| `Petrify` | live value turned to stone. Memorable. |
| `Engrave` | engrave a runtime value into source. |
| `Reify` | precise, slightly academic. |

## P6 — not started

- [ ] Compare against pointfreeco/swift-debug-snapshots and borrow test cases.
- [ ] CI that runs the round-trip typecheck on every push.
- [ ] Decide whether `ValueRendererRegistry` should be scoped rather than global.
