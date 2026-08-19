# Progress log

Append-only. Newest at the bottom. Written so no work gets redone.

Names in the early entries are the names as they were at the time. The rename to
SwiftLiteral is the last entry.

## 2026-08-19 — survey

Read the whole source tree. Ran the suite.

**`swift test` segfaulted on `main`.** Not a flake, deterministic. Crash in
`targetLevelReflectionExtractionAppliesRedaction`, the test added by the most recent
commit (#46).

Root cause: `xctest-dynamic-overlay` 1.7.0. Its `reportIssue` reads swift-testing's
`Test.current`, and against the 6.3.3 toolchain that read is an over-release:
`_currentTest()` -> `outlined destroy of Test?` -> `EXC_BAD_ACCESS`. The library called
`reportIssue` on every reflection render, as a logger, so any reflected value crashed the
process. Pinning `from: "1.11.0"` fixes it.

Also checked: `swift package update` alone does not fix it, and swift-snapshot-testing
1.19.4 does not compile against the 6.3.3 toolchain at all (`Attachment` requires
`Data: Attachable`). Pinned to `"1.18.0"..<"1.19.0"`.

## 2026-08-19 — P0 through P4

**`swift test` passes. 197 tests, 21 suites.**

### Removed

- **swift-dependencies.** `SwiftSnapshotConfigClient` was 13 closures wrapping static
  functions, with `testValue` set to `.live`. Zero test isolation, one dependency.
  See "Open question" at the bottom of this file.
- **The macro-expression-string path.** `__swiftSnapshot_makeExpr` produced
  `TestProduct(id: 123, name: Widget)` — unquoted strings, not compilable Swift. The
  source comments already admitted it did not work. Gone, along with
  `useMacroGeneratedExpressions` and `renderSwiftSnapshotExportable`.
- **Pointer dereferencing.** `tryDereferencePointer` cast an `UnsafeMutablePointer` to a
  list of thirty likely types, and `extractCurrentValueFromPublisher` walked Combine
  internals looking for a field named `currentValue`. When they guessed wrong, the value
  became `nil` and the file was written anyway.
- **`SwiftSnapshotBootstrap.registerDefaults()`**, which had an empty body.
- **`reportIssue` as a logger.** The renderer reported an issue on every top-level
  render, on every optional, on every struct. In a test, `reportIssue` is a failure.

### Split

New reflection target: value in, `ExprSyntax` out. No file I/O, no global config. The core
target keeps configuration, formatting, path resolution, and writing. `ValueRenderer` went
from 1384 lines to about 360.

### Fixed

Every one of these is covered by the round-trip typecheck test.

| Was | Now |
|---|---|
| `[1: "a"]` rendered `["1": "a"]` — keys stringified through `[AnyHashable: Any]` | Keys keep their type. Collections go through `Mirror`, not casts. |
| Enum case names came from `String(describing:)`, so a `CustomStringConvertible` enum rendered its description | Case names come from the runtime (`swift_EnumCaseName`) |
| `case move(x: Int, y: Int)` rendered `.move((x: 1, y: 2))` — the payload tuple as one argument | `.move(x: 1, y: 2)` |
| A failed render became `nil`, and the file was written | It throws |
| `export` swallowed every error and returned a `/tmp/swift-snapshot-error` URL | It throws |
| Redaction applied at the top level only, so a nested secret was written in the clear | Redaction applies at every depth |
| `@SnapshotRename` was ignored on the reflection path | The new label is used |
| Ranges rendered `Range<Int>(lowerBound: 1, upperBound: 5)`, which has no such initializer | `1..<5` |
| Every non-ASCII character became `\u{...}` | Accents and emoji stay themselves |
| `Set([1, 2])`, which cannot infer its element type in an argument position | `[1, 2]` |
| `Int8(5)`, `UInt64(3)` and nine more wrapper spellings, 130 lines of near-identical builders | Plain literals |
| `Int??.some(nil)` collapsed to `nil` | `.some(nil)` |
| `indent(level:)` returned spaces even when the profile said tabs | Tabs when asked for tabs |

### Testing

A new test target holds the test that matters: `everySampleTypechecks` renders the whole
sample matrix, writes it next to the real type declarations, and runs
`swiftc -typecheck -swift-version 6` over both. Parsing was never enough — `User(name: nil)`
parses.

The same run pins the exact generated text as a snapshot, so a rendering change shows up in
a diff instead of passing silently.

Matrix covers: primitives, sized integers, nested optionals, arrays, dictionaries with
`Int` and enum keys, sets, empty collections, `Date`/`UUID`/`URL`/`Data`/`Decimal`, ranges,
raw and payload enums, an enum that lies in its `description`, nested structs, classes,
property wrappers, generics, a custom `Collection`, escaping, `Int.max`, infinity, NaN, and
subnormals.

## 2026-08-19 — rename to SwiftLiteral

"Snapshot" reads as swift-snapshot-testing and set the wrong expectation before anyone got
to the first code sample. Modules only; the repository stays at `swift-snapshot`.

    SwiftSnapshot           -> SwiftLiteral
    SwiftSnapshotCore       -> SwiftLiteralCore
    SwiftSnapshotReflection -> SwiftLiteralReflection
    SwiftSnapshotMacros     -> SwiftLiteralMacros

    @SwiftSnapshot          -> @SwiftLiteral
    @SnapshotIgnore         -> @LiteralIgnore
    @SnapshotRename         -> @LiteralRename
    @SnapshotRedact         -> @LiteralRedact

The entry point was reshaped at the same time:

    SwiftSnapshotRuntime.export(instance: user, variableName: "testUser")
    try Literal.write(user, named: "testUser")
    try Literal.source(of: user, named: "testUser")

`source` is public now. Rendering to a string without writing a file is a reasonable thing
to want, and it was internal for no reason.

## 2026-08-19 — docs

README rewritten. DocC cut from ten articles to five and rewritten:

- `WhatAndWhy` — the argument, stated once
- `Architecture` — four targets and the pipeline
- `Comparisons` — vs swift-snapshot-testing, vs swift-debug-snapshots, vs JSON
- `Limits` — every case reflection cannot handle, and what to do instead
- `CustomRenderers` — how to write one
- `Formatting` — editorconfig and swift-format mapping

Deleted: `BasicUsage` and `BestPractices` (README covers them), `EditorConfigMapping` and
`EditorConfigVerification` and `FormattingConfiguration` (three articles about one subject,
now one), `StabilityAndSupportTiers` (described tiers that no longer exist),
`SwiftSnapshotVsDebugSnapshots` (folded into `Comparisons`).

While restoring the custom-`Collection` branch that the rewrite had dropped, found that
`GenericCollectionTests` only asserted `code.contains("GenericWrapper<Int>")`, which passes
whether or not the output compiles. Added a custom `Collection` to the round-trip matrix so
that branch is actually checked.

## Open question — swift-dependencies

`dktunited/swift-shared-agent` requires global state to go through `@Dependency`, and calls
out hardcoded singletons as a threat to test determinism. This branch currently has two:

- `LiteralConfig`, static state behind an `NSLock`
- `ValueRendererRegistry.shared`

The client that was removed did not satisfy that rule either — its `testValue` was `.live`,
so `withDependencies` overrides were the only isolation and nothing was `.unimplemented`.
Removing it was not what fixed the crash; pinning `xctest-dynamic-overlay` was.

The engine target is already clean: no globals, options passed in explicitly. The question
is only about the core target. Decide before 0.3.0.
