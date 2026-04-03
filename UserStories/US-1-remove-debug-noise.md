# US-1 · Remove Debug Noise from Renderer

**Epic**: A – Correctness Fixes  
**Priority**: P0  
**Status**: ✅ Implemented

---

## User Story

> As a developer using SwiftSnapshot in my test suite, I want rendering to never call
> `reportIssue` on the happy path, so that my test runs are not polluted with spurious
> issue reports or unexpected test failures.

---

## Background

`reportIssue` (from `xctest-dynamic-overlay` / `IssueReporting`) is an **error-reporting**
tool: in XCTest it calls `XCTFail`; in Swift Testing it calls `Issue.record`. Calling it on
a successful render is incorrect and causes noise or outright test failures.

Three informational log calls were left in production code:

| Location | Call | Problem |
|----------|------|---------|
| `render(_:context:)` line ~160 | Reports every top-level Optional render | Fires for any `Optional?` property at root |
| `renderViaReflection(_:context:)` line ~729 | Reports every top-level struct/class render | Fires for **every** custom type |
| `renderStructViaReflection(…)` line ~898 | Reports struct child count | Fires redundantly alongside the above |

---

## Acceptance Criteria

1. Rendering a plain struct emits **zero** calls to `reportIssue`.
2. Rendering a non-nil top-level `Optional` emits **zero** calls to `reportIssue`.
3. Rendering a nil top-level `Optional` emits **zero** calls to `reportIssue`.
4. All three informational `reportIssue` calls are removed from `ValueRenderer.swift`.
5. Existing tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/DebugNoiseTests.swift`

```swift
// Renders a plain struct → no issues should be reported
@Test func renderingPlainStructEmitsNoSpuriousIssues() throws { … }

// Renders a top-level non-nil Optional → no issues
@Test func renderingNonNilOptionalEmitsNoSpuriousIssues() throws { … }

// Renders a top-level nil Optional → no issues
@Test func renderingNilOptionalEmitsNoSpuriousIssues() throws { … }

// Nested struct tree → no issues
@Test func renderingNestedStructsEmitsNoSpuriousIssues() throws { … }
```

---

## Fix

Remove the three `if context.path.isEmpty { reportIssue(…) }` blocks from
`ValueRenderer.swift`. These are pure informational logs; the error-reporting path is
already handled by `throw SwiftSnapshotError.*` cases and the remaining `reportIssue`
calls that fire on genuine failures (e.g., unsafe pointer encountered, raw-value render
failed).
