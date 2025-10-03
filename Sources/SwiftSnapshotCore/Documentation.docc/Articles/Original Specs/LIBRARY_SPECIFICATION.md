# SwiftSnapshot Library Specification (macOS-only, Swift-Only Rendering)

Status: Draft  
Platform: macOS (Apple Swift toolchain)  
Scope: Runtime library for generating Swift source fixtures (single Swift renderer only)  
Non-Goals: Multi-format rendering (no JSON/Markdown outputs), cross-platform portability (Linux), migration strategy, separate snapshot IR layer.

## 1. Purpose

Provide a lightweight, deterministic way to export in‑memory Swift values as compilable Swift source fixtures for tests, previews, diagnostics, and documentation—without introducing a custom intermediate representation. SwiftSyntax is leveraged directly to model and emit the code.

## 2. Key Principles

1. Swift-Only Output: Only generates Swift fixture files (no alternate formats).
2. No IR Layer: Direct construction of `SwiftSyntax` nodes from values (macro-assisted when possible).
3. macOS Only (initially): Avoid conditional compilation until explicitly expanded.
4. Extensible Rendering: Custom value renderers auto-register via a static registration pattern (inspired by snapshot-testing PR #906 technique).
5. Deterministic Output: Stable ordering and formatting.
6. Minimal Runtime Footprint: Reflection used only when macro metadata unavailable.
7. Configurable Headers: Optional custom header block at top of each generated file.
8. Safe Defaults: Overwrite behavior controlled; path resolution layered.

## 3. High-Level Architecture

| Component | Responsibility |
|-----------|----------------|
| SwiftSnapshotCore | Public API, export pipeline, path + header configuration, reflection fallback |
| SwiftSnapshotRendering (logical grouping) | Built‑in renderers for primitives, Foundation, collections |
| SwiftSnapshotMacro (separate target; see macro spec) | Supplies compile-time synthesized extraction/render metadata |
| Formatting Layer | Loads `.swift-snapshot-format` and applies indentation, trailing newline, etc. |
| Registry | Holds type-specific render closures (auto-registered) |

A single SPM product `SwiftSnapshot` re-exports `SwiftSnapshotCore` + formatting + registry.

## 4. Public Runtime API

```
public enum SwiftSnapshotRuntime {

  @discardableResult
  public static func export<T>(
    instance: T,
    variableName: String,
    fileName: String? = nil,        // Optional explicit file base name
    outputBasePath: String? = nil,  // Directory override
    allowOverwrite: Bool = true,
    header: String? = nil,          // File header (overrides global header if provided)
    context: String? = nil,         // Optional doc comment block above declaration
    testName: String? = nil,        // Optional grouping hint
    line: UInt = #line,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath
  ) throws -> URL

  // Internal: generateSwiftCode is used internally by export() and in tests
  internal static func generateSwiftCode<T>(
    instance: T,
    variableName: String,
    header: String? = nil,
    context: String? = nil
  ) throws -> String
}
```

### Runtime Convenience (Macro-Augmented Types)
When a type is annotated with `@SwiftSnapshot` (see macro spec), an instance method is made available:
```
try model.exportSnapshot(variableName: "sampleOrder", testName: #function, header: "/* Fixtures */")
```

## 5. Configuration

```
public enum SwiftSnapshotConfig {
  public static func setGlobalRoot(_ url: URL)
  public static func getGlobalRoot() -> URL?
  public static func setGlobalHeader(_ header: String?)
  public static func getGlobalHeader() -> String?
  public static func setFormattingProfile(_ profile: FormatProfile)
  public static func formattingProfile() -> FormatProfile
}
```

Resolution (highest → lowest):
1. `outputBasePath` argument
2. `SwiftSnapshotConfig.setGlobalRoot`
3. Environment variable `SWIFT_SNAPSHOT_ROOT`
4. (Macro parameter `folder:` — macro side)
5. Default: `__Snapshots__` adjacent to originating test file if path indicates a test target (`/Tests/` heuristic), else `NSTemporaryDirectory()`.

## 6. File Structure

Generated file layout:

```
<Header Block if any>
import Foundation

extension <TypeName> {
  <Optional Context Doc Comment>
  /// (Context lines)
  static let <variableName>: <TypeName> = <Expression>
}
```

- `Header` inserted verbatim at top (no auto-prefixing). Recommended to include comment markers.
- `Context` is converted to a properly formatted Swift doc comment placed inside the extension, above the variable declaration:
  - Each non-empty line prefixed with `///`
  - Blank lines preserved
- Always ensures trailing newline (if formatting profile demands it).

## 7. Formatting

Loaded from `.swift-snapshot-format` (project root search upward) then `.editorconfig`, else defaults:

| Key | Default | Meaning |
|-----|---------|---------|
| indent_style | `space` | Only `space` supported initially |
| indent_size | `4` | Spaces per indent |
| end_of_line | `lf` | Line ending style |
| insert_final_newline | `true` | Ensure EOF newline |
| trim_trailing_whitespace | `true` | Strip trailing spaces per line |

`FormatProfile` (internal struct) drives an idiomatic code printer that:
- Emits multi-line initializer argument lists with trailing commas
- Canonically sorts dictionary keys (stringifiable keys) ascending
- Stabilizes set literal ordering by ascending description

## 8. Value Rendering (Core)

### 8.1 Built-In Support
- Primitives: `String`, `Int`, `Double`, `Float`, `Bool`, `Character`
- Foundation: `Date`, `UUID`, `URL`, `Decimal`, `Data`
- Collections: `Array`, `Dictionary`, `Set`
- Optionals
- RawRepresentable enums (dot syntax when case can be inferred; fallback `Type(rawValue:)`)
- Associated Value Enums (macro required for full labels; Mirror fallback uses unlabeled tuple sequence)
- Structs & Classes: Memberwise initializer attempt; fallback to synthetic initializer-like expansion using property enumeration
- Nested types resolved recursively

### 8.2 Rendering Strategy (No IR)
The renderer builds an `ExprSyntax` tree directly:

- Strings escaped via Swift literal rules
- Dates rendered as `Date(timeIntervalSince1970: <Double>)`
- Data:
  - If size ≤ 16 bytes: `Data([0xHH, ...])`
  - Else: Base64: `Data(base64Encoded: "<...>")!`
- Dictionaries: `[\n  "key": value,\n]`
- Sets: Represented as `Set([ ... ])` to preserve determinism; order produced by sorted element textual form
- Enums:
  - If macro metadata exists: `.caseName(arg1: ..., arg2: ...)`
  - Else attempt introspection:
    - RawRepresentable with a match: `.caseName` if value’s `rawValue` string matches a valid identifier, else `Type(rawValue: "...")!`

### 8.3 Reflection Fallback
Reflection chooses:
1. Determine dynamic type
2. If `CustomRenderer` exists (registry match) use it
3. If enum: decode case via `Mirror(children:)` heuristics (limited reliability)
4. If struct/class: enumerate children, build argument list initializer if all labels non-nil; else construct sequential unlabeled initializer if such an init is assumed (if not possible, fallback to property-wise assignment pattern stub—future extension)

### 8.4 Failure Modes
If a value is unsupported:
- Throws `SwiftSnapshotError.unsupportedType`
- Export call surfaces user-friendly message including path (breadcrumb of member traversal).

## 9. Custom Type Rendering (Auto Registration Pattern)

### 9.1 Goal
Allow users to define custom renderers that are automatically registered without needing manual central listing, using static registration side effects (pattern inspired by pointfreeco’s auto-registration approach).

### 9.2 Protocol
```
public protocol SnapshotCustomRenderer {
  associatedtype Value
  static func render(_ value: Value, context: SnapshotRenderContext) throws -> ExprSyntax
}
```

### 9.3 Registry
```
public final class SnapshotRendererRegistry {
  public static let shared = SnapshotRendererRegistry()

  public func register<Value>(
    _ type: Value.Type,
    render: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
  )

  public func renderer(for value: Any) -> ((Any, SnapshotRenderContext) throws -> ExprSyntax)?
}
```

### 9.4 Auto-Registration Pattern
User defines:

```
struct URLRenderer: SnapshotCustomRenderer {
  static func render(_ value: URL, context: SnapshotRenderContext) throws -> ExprSyntax {
    ExprSyntax(stringLiteral: "URL(string: \(literal(value.absoluteString)))!")
  }
}

// Static token triggers registration at load:
extension URLRenderer {
  private static let _registration: Void = {
    SnapshotRendererRegistry.shared.register(URL.self) { url, ctx in
      try URLRenderer.render(url, context: ctx)
    }
  }()
}

// Ensure evaluation (one-time) in test bootstrap or module init:
private let _forceURLRendererRegistration: Void = {
  _ = URLRenderer._registration
}()
```

Optionally the library exposes:
```
public enum SwiftSnapshotBootstrap {
  public static func registerDefaults() {
    _ = BuiltInRenderers._registrationBundle  // internal grouping
  }
}
```

Users add their registrations in a similar “force” grouping.

### 9.5 Convenience Helper (Optional)
Provide:
```
public func autoregister<Value>(
  _ type: Value.Type,
  using block: @escaping (Value, SnapshotRenderContext) throws -> ExprSyntax
) -> Void
```
So a custom renderer can just do:
```
private let _ = autoregister(MyType.self) { value, ctx in ... }
```

### 9.6 SnapshotRenderContext
```
public struct SnapshotRenderContext {
  public let path: [String]        // breadcrumb within the object graph
  public let formatting: FormatProfile
  public let options: RenderOptions
}

public struct RenderOptions {
  public var sortDictionaryKeys: Bool
  public var setDeterminism: Bool
  public var dataInlineThreshold: Int
  public var forceEnumDotSyntax: Bool
}
```

Global defaults in `SwiftSnapshotConfig`.

## 10. Headers

### 10.1 Global Header
Set once:
```
SwiftSnapshotConfig.setGlobalHeader("""
/*
//  Project Fixtures
//  Generated by SwiftSnapshot
*/
""")
```

### 10.2 Per-Export Override
`export(... header: "...")` overrides global header for that file.

### 10.3 No Header Behavior
If neither global nor local header is provided, file begins directly with context doc comment or imports.

## 11. Error Types

```
public enum SwiftSnapshotError: Error, CustomStringConvertible {
  case unsupportedType(String, path: [String])
  case io(String)
  case overwriteDisallowed(URL)
  case formatting(String)
  case reflection(String, path: [String])

  public var description: String { ... }
}
```

## 12. Determinism Rules

| Aspect | Rule |
|--------|------|
| Dictionary Keys | Sort lexicographically if `options.sortDictionaryKeys == true` |
| Set Elements | Sort by rendered description if `options.setDeterminism == true` |
| Trailing Commas | Always for multi-line collections (simplifies diffs) |
| File Imports | Always at top, canonical order (Foundation first) |
| Enum Dot Style | If `forceEnumDotSyntax == true` and pattern recognized |

## 13. Safety Considerations

| Concern | Mitigation |
|---------|-----------|
| Path traversal | Normalize and ensure target is within resolved root unless explicit absolute override passed |
| Sensitive fields | Up to user; library may optionally add `@SnapshotRedact` handling when combined with macro (handled macro side) |
| Malicious strings | Properly escapes quotes, backslashes, newlines, control chars |
| Overwrite risk | `allowOverwrite` default `true` but can be set `false` to fail fast |

## 14. Performance Considerations

| Technique | Description |
|-----------|-------------|
| Iterative String Assembly | Use `TextOutputStream` accumulators rather than naive concatenation |
| Lazy Registration Snapshot | Registry captured once per export call |
| Avoid Unnecessary Mirror | Prefer macro metadata; reflection only when needed |
| Short-Circuit Primitives | Direct literal emission without intermediate objects |

## 15. Minimal Example

```
struct User {
  let id: Int
  let name: String
}

let user = User(id: 42, name: "Alice")
try SwiftSnapshotRuntime.export(instance: user, variableName: "testUser")
```

Generates:

```swift
//  Generated by SwiftSnapshot

import Foundation

extension User {
  static let testUser: User = User(
    id: 42,
    name: "Alice"
  )
}
```

## 16. Future (Explicitly Deferred)

- Cross-platform guards
- Plugin-driven bulk regeneration
- Graph cycle detection
- Property-level transformers (macro could add)
- Deduplicated sub-object factoring

---