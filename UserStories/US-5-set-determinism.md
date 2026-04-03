# US-5 · Deterministic Set Ordering

**Epic**: C – Safety & Robustness  
**Priority**: P2  
**Status**: 🔲 Not implemented

---

## User Story

> As a developer, I want `Set` values to always render in the same order across builds and
> platforms, so that my snapshot diffs are stable and don't show false changes.

---

## Background

`renderSet` sorts elements by `"\($0)" < "\($1)"` — a lexicographic comparison of each
element's `String(describing:)` output. This is wrong in two ways:

1. **Numeric order is broken**: `"10" < "2"` lexicographically, so `Set([1, 2, 10])` may
   render as `Set([1, 10, 2])`.
2. **Complex-type stability**: For structs/classes, `String(describing:)` can produce
   different output across Swift versions, making snapshots fragile.

The fix is to render each element to its final `ExprSyntax` string representation first,
then sort by *that* rendered string. Because the rendered string is deterministic (it is
the output we produce), sorting it gives consistent, reproducible order.

---

## Acceptance Criteria

1. `Set<Int>` containing `[10, 2, 1, 5]` always renders as `Set([1, 2, 5, 10])`.
2. `Set<String>` renders in lexicographic order of the string values.
3. `Set<UUID>` renders in the same order across two separate calls with identical content.
4. All existing set-related tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/SetDeterminismTests.swift`

```swift
// Integers must be in numeric-ish order (sorted by rendered string)
@Test func setOfIntsIsStable() throws { … }

// Strings sort lexicographically
@Test func setOfStringsIsLexicographicallyOrdered() throws { … }

// Two calls with the same UUID set produce identical output
@Test func setOfUUIDsIsStableAcrossCalls() throws { … }
```

---

## Fix

In `renderSet`, render elements first then sort by rendered representation:

```swift
static func renderSet(_ set: Set<AnyHashable>, context: SnapshotRenderContext) throws -> ExprSyntax {
    var rendered: [(expr: ExprSyntax, key: String)] = []
    for element in set {
        let expr = try render(element, context: context)
        rendered.append((expr, expr.description))
    }
    if context.options.setDeterminism {
        rendered.sort { $0.key < $1.key }
    }
    // Build array from sorted exprs...
}
```
