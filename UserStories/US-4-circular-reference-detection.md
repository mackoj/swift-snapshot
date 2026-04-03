# US-4 · Circular Reference Detection

**Epic**: C – Safety & Robustness  
**Priority**: P1  
**Status**: 🔲 Not implemented

---

## User Story

> As a developer, I want the renderer to detect circular object references and throw a
> clear error instead of hanging the process, so I can safely render real-world class
> hierarchies that may contain back-references.

---

## Background

`renderStructViaReflection` recurses through `Mirror.children` without tracking which
class instances have already been visited. A class that holds a reference back to itself
(or an ancestor) causes unbounded recursion and eventual stack overflow:

```swift
final class Node {
    var value: Int
    var next: Node?
}
let n = Node(value: 1)
n.next = n  // circular!
try ValueRenderer.render(n, context: .default)  // → infinite loop / crash
```

`struct` types are value types and cannot form cycles; only `class` instances can.

---

## Acceptance Criteria

1. A self-referential class instance throws `SwiftSnapshotError.circularReference`.
2. A mutually-referential pair (A → B → A) also throws.
3. A long linear chain (no cycle) renders successfully.
4. The new `circularReference` case is added to `SwiftSnapshotError` with the type name
   and path.
5. `SnapshotRenderContext` gains a `visitedObjectIDs: Set<ObjectIdentifier>` property
   (internal, not public API).
6. All existing tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/CircularReferenceTests.swift`

```swift
// Self-referential node must throw, not hang
@Test func selfReferentialClassThrowsError() throws { … }

// Mutual reference (A → B → A) must throw
@Test func mutuallyReferentialClassesThrowError() throws { … }

// Long linear chain (no cycle) must succeed
@Test func deepLinearChainSucceeds() throws { … }

// Error carries the type name and path
@Test func circularReferenceErrorContainsContext() throws { … }
```

---

## Fix

1. Add `circularReference(String, path: [String])` to `SwiftSnapshotError`.
2. Add an internal `visitedObjectIDs: Set<ObjectIdentifier>` field to
   `SnapshotRenderContext`.
3. In `renderStructViaReflection`, for `.class` display style, check and insert the
   object identity before recursing:

```swift
if mirror.displayStyle == .class {
    let id = ObjectIdentifier(value as AnyObject)
    guard !context.visitedObjectIDs.contains(id) else {
        throw SwiftSnapshotError.circularReference(typeName, path: context.path)
    }
    context = context.addingVisitedID(id)
}
```
