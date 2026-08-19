# swift-snapshot: rebuild plan

Branch: `rework/tests-reflection-docs` (PR #49)

Checked items are done and verified. Do not redo them. What happened is in PROGRESS.md.

## Decisions taken (2026-08-19)

- Breaking changes allowed. 0.x, break freely.
- Tests really typecheck the generated code. Parsing is not enough.
- The reflection engine gets its own target.
- Renamed to SwiftLiteral. Modules only; the repository stays `swift-snapshot`.

## Done

- [x] **P0** — `swift test` was segfaulting on `main`. Cause: `xctest-dynamic-overlay`
      1.7.0 against the 6.3.3 toolchain. 197 tests pass now.
- [x] **P1** — `SwiftLiteralReflection` split out. Value in, `ExprSyntax` out, no globals.
- [x] **P2** — round-trip typecheck harness plus a pinned golden file.
- [x] **P3** — thirteen correctness bugs the harness exposed. Table in PROGRESS.md.
- [x] **P4** — deleted the macro-expression path, the pointer dereferencing, the empty
      bootstrap, and `reportIssue`-as-logger.
- [x] **P5** — renamed to SwiftLiteral, rewrote the README, cut DocC from ten articles to
      six and rewrote them.

## Next

- [ ] **Decide on swift-dependencies.** See "Open question" in PROGRESS.md. The house rules
      say global state goes through `@Dependency`; this branch has two singletons.
- [ ] **CI.** No workflow runs `swift test` on push. The suite was broken for months and
      nothing said so.
- [ ] **Tag 0.3.0.** The README points at it. `0.2.0` already exists and is the old API.
- [ ] Borrow test cases from pointfreeco/swift-debug-snapshots.
- [ ] Consider whether `ValueRendererRegistry` should be scoped rather than global.

## Known weak spots

- `PerformanceTests` asserts on wall-clock time. That is a flake waiting for a slow CI box.
- `ManualSanitizationVerification` duplicates `VariableNameSanitizationTests`.
- The custom-`Collection` branch is the one place the renderer guesses at a shape it
  cannot verify. Documented in `Limits`.
