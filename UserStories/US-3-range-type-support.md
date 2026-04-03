# US-3 · Range & ClosedRange Type Support

**Epic**: B – Type Coverage  
**Priority**: P1  
**Status**: ✅ Implemented

---

## User Story

> As a developer, I want `Range<Int>` and `ClosedRange<Int>` values to render as `1..<5`
> and `1...5`, so I can include range properties in my fixture types.

---

## Background

`Range<Bound>` and `ClosedRange<Bound>` both conform to `Collection`. Without a dedicated
handler they are caught by the generic `renderCollection` path, which renders them as:

```swift
Range<Int>([1, 2, 3, 4])   // invalid — Range has no such initialiser
```

The dedicated handlers must be inserted **before** the generic `Collection` check in
`render(_:context:)`.

---

## Acceptance Criteria

1. `Range<Int>` renders as `1..<5`.
2. `ClosedRange<Int>` renders as `1...5`.
3. `Range<Double>` renders as `1.5..<3.0`.
4. `ClosedRange<String>` renders as `"a"..."z"`.
5. A range nested inside a struct renders correctly.
6. All existing tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/RangeTypesTests.swift`

```swift
@Test func openRangeOfInt() throws { … }         // 1..<5
@Test func closedRangeOfInt() throws { … }        // 1...5
@Test func openRangeOfDouble() throws { … }       // 1.5..<3.0
@Test func closedRangeOfString() throws { … }     // "a"..."z"
@Test func rangeInsideStruct() throws { … }       // Range as struct property
```

---

## Fix

Add typed checks before the generic `Collection` case in `render(_:context:)`:

```swift
// Range types – must come before `any Collection` check
if let r = value as? Range<Int>         { return renderRange(r, context: context) }
if let r = value as? ClosedRange<Int>   { return renderClosedRange(r, context: context) }
if let r = value as? Range<Double>      { return renderRange(r, context: context) }
if let r = value as? ClosedRange<Double>{ return renderClosedRange(r, context: context) }
if let r = value as? Range<String>      { return renderRange(r, context: context) }
if let r = value as? ClosedRange<String>{ return renderClosedRange(r, context: context) }
```

With helpers:
```swift
static func renderRange<B>(_ r: Range<B>, context: SnapshotRenderContext) throws -> ExprSyntax
static func renderClosedRange<B>(_ r: ClosedRange<B>, context: SnapshotRenderContext) throws -> ExprSyntax
```
