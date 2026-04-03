# US-6 · `Result<Success, Failure>` Support

**Epic**: B – Type Coverage  
**Priority**: P2  
**Status**: 🔲 Not implemented

---

## User Story

> As a developer, I want `Result<Success, Failure>` values to render as `.success(value)`
> or `.failure(error)`, so I can use `Result` in my fixture types without registering a
> custom renderer.

---

## Background

`Result` has no dedicated handler in `ValueRenderer`. It falls through to
`renderEnumViaReflection`, which tries to treat it as a `RawRepresentable` enum (it isn't)
and then falls back to the associated-value path. Mirror-based reflection of `Result`
exposes its internal storage rather than the `.success`/`.failure` case names, producing
output like:

```swift
Result<String, AppError>()   // meaningless; doesn't compile
```

---

## Acceptance Criteria

1. `Result<String, AppError>.success("ok")` renders as `.success("ok")`.
2. `Result<String, AppError>.failure(.notFound)` renders as `.failure(.notFound)`.
3. Nested `Result` (e.g. a struct property) renders correctly.
4. Works for any `Success` and `Failure` types that are themselves renderable.
5. All existing tests continue to pass.

---

## Tests

File: `Tests/SwiftSnapshotTests/ResultTypeTests.swift`

```swift
enum AppError: Error { case notFound; case unauthorized }

@Test func successResult() throws { … }       // .success("ok")
@Test func failureResult() throws { … }       // .failure(.notFound)
@Test func resultInsideStruct() throws { … }  // Result as struct property
@Test func nestedSuccessResult() throws { … } // Result<[Int], Error>
```

---

## Fix

Use a protocol-based bridge (since `Result` cannot be cast directly with existential
wildcards in Swift 6) to extract the case:

```swift
private protocol _ResultProtocol {
    var _successValue: Any? { get }
    var _failureValue: (any Error)? { get }
}
extension Result: _ResultProtocol {
    var _successValue: Any? { if case .success(let v) = self { return v }; return nil }
    var _failureValue: (any Error)? { if case .failure(let e) = self { return e }; return nil }
}
```

Then in `render(_:context:)` before the reflection fallback:
```swift
if let result = value as? any _ResultProtocol {
    return try renderResult(result, context: context)
}
```
