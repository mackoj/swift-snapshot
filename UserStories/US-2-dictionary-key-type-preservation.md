# US-2 · Dictionary Key Type Preservation

**Epic**: A – Correctness Fixes  
**Priority**: P0  
**Status**: ✅ Implemented

---

## User Story

> As a developer, I want `[Int: String]` dictionaries to render as `[1: "one"]` instead of
> `["1": "one"]`, so that the generated Swift fixture code actually compiles.

---

## Background

`renderDictionary` converts every key to a `String` via string interpolation before
storing it in the pairs array. The original `AnyHashable` value is discarded. When the
key is then rendered by `render(pair.key, …)` it calls `renderString` and emits a Swift
`String` literal — even when the original key was `Int`, `UUID`, an enum, etc.

```swift
// Current (broken)
for (key, value) in dict {
    pairs.append((key: "\(key)", value: value))  // key is now a String "1"
}
let keyExpr = try render(pair.key, context:)      // renders "1" as a String literal
```

For a dictionary of type `[Int: String]`, the produced code is:
```swift
["1": "one", "2": "two"]   // ← does NOT compile as [Int: String]
```

---

## Acceptance Criteria

1. `[Int: String]` renders as `[1: "one", 2: "two"]`.
2. `[UUID: Int]` renders using `UUID(uuidString: "…")!` as the key expression.
3. Dictionary key sort order is preserved (keys are still sorted by their string
   representation for determinism, but the *rendered* key uses the original type).
4. Nested dictionaries also preserve key types.
5. Existing string-keyed dictionary tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/DictionaryKeyTests.swift`

```swift
// [Int: String] keys must render as integer literals
@Test func intKeyDictionary() throws { … }

// [UUID: Int] keys must render as UUID(uuidString:)!
@Test func uuidKeyDictionary() throws { … }

// [Bool: String] keys
@Test func boolKeyDictionary() throws { … }

// Nested [String: [Int: String]] – inner dict keys preserved
@Test func nestedDictionaryKeyTypes() throws { … }
```

---

## Fix

Store the original `AnyHashable` key alongside the sorting string, and render the
original key value:

```swift
var pairs: [(sortKey: String, originalKey: AnyHashable, value: Any)] = []
for (key, value) in dict {
    pairs.append((sortKey: "\(key)", originalKey: key, value: value))
}
if context.options.sortDictionaryKeys {
    pairs.sort { $0.sortKey < $1.sortKey }
}
// …
let keyExpr = try render(pair.originalKey.base, context: keyContext)
```
