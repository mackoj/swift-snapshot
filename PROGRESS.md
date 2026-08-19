# Progress log

Append-only. Newest at the bottom. Written so no work gets redone.

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

## 2026-08-19 — P0 through P4 landed

**`swift test` passes. 197 tests, 21 suites.**

### Removed

- **swift-dependencies.** `SwiftSnapshotConfigClient` was 13 closures wrapping static
  functions, with `testValue` set to `.live`. Zero test isolation, one dependency.
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

New `SwiftSnapshotReflection` target: value in, `ExprSyntax` out. No file I/O, no global
config. `SwiftSnapshotCore` keeps configuration, formatting, path resolution, and writing.
`ValueRenderer` went from 1384 lines to about 340.

### Fixed

Every one of these is covered by the round-trip typecheck test.

| Was | Now |
|---|---|
| `[1: "a"]` rendered `["1": "a"]` — keys stringified through `[AnyHashable: Any]` | Keys keep their type. Collections go through `Mirror`, not casts. |
| Enum case names came from `String(describing:)`, so a `CustomStringConvertible` enum rendered its description | Case names come from the runtime (`swift_EnumCaseName`) |
| `case move(x: Int, y: Int)` rendered `.move((x: 1, y: 2))` — the payload tuple was passed as one argument | `.move(x: 1, y: 2)` |
| A failed render became `nil`, and the file was written | It throws |
| `export` swallowed every error and returned a `/tmp/swift-snapshot-error` URL | `export` throws |
| Redaction applied at the top level only, so a nested secret was written in the clear | Redaction applies at every depth |
| `@SnapshotRename` was ignored on the reflection path | The new label is used |
| Ranges rendered `Range<Int>(lowerBound: 1, upperBound: 5)`, which has no such initializer | `1..<5` |
| Every non-ASCII character became `\u{...}` | Accents and emoji stay themselves |
| `Set([1, 2])`, which cannot infer its element type in an argument position | `[1, 2]` |
| `Int8(5)`, `UInt64(3)` and nine more wrapper spellings, 130 lines of near-identical builders | Plain literals |
| `Int??.some(nil)` collapsed to `nil` | `.some(nil)` |
| `indent(level:)` returned spaces even when the profile said tabs | Tabs when asked for tabs |

### Testing

`Tests/SwiftSnapshotReflectionTests` is new and holds the test that matters:
`everySampleTypechecks` renders the whole sample matrix, writes it next to the real type
declarations, and runs `swiftc -typecheck -swift-version 6` over both. Parsing was never
enough — `User(name: nil)` parses.

The same run pins the exact generated text as a snapshot, so a rendering change shows up
in a diff instead of passing silently.

Matrix covers: primitives, sized integers, nested optionals, arrays, dictionaries with
`Int` and enum keys, sets, empty collections, `Date`/`UUID`/`URL`/`Data`/`Decimal`,
ranges, raw and payload enums, an enum that lies in its `description`, nested structs,
classes, property wrappers, generics, escaping, `Int.max`, infinity, NaN, and subnormals.

### Still to do

P5. See PLAN.md.
