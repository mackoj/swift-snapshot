# SwiftSnapshot Macro Implementation Plan (macOS Only, Swift Renderer Only)

Status: Draft  
Scope: `@SwiftSnapshot` macro + property annotations generating compile-time extraction/render metadata and convenience export API.  
Out of Scope: Multi-format outputs, separate IR model, cross-platform support.

---

## 1. Goals

| Goal | Description |
|------|-------------|
| Deterministic Field Ordering | Preserve source order for properties |
| Enum Case Reconstruction | Complete case + associated value label capture |
| Attribute-Driven Control | Ignore, rename, redact instructions embedded at compile time |
| Direct Expression Generation | Build `ExprSyntax` initializer fragment for the instance |
| Minimal Public Surface | Expose only `@SwiftSnapshot` & a minimal attribute set initially |
| Runtime Synergy | Enable runtime to skip reflection for macro-instrumented types |

Use https://github.com/pointfreeco/swift-macro-testing for macro testing when possible.

---

## 2. Macros & Attributes

| Macro/Attr | Level | Purpose |
|------------|-------|---------|
| `@SwiftSnapshot(folder:context:)` | Type | Enables generation; optional output folder hint; doc context |
| `@SnapshotIgnore` | Property | Exclude from output |
| `@SnapshotRename("newLabel")` | Property | Rename initializer label |
| `@SnapshotRedact(mask: String? = nil, hash: Bool = false, remove: Bool = false)` | Property | Replace/mask/hash/omit value at macro time |

(Other extensions, like custom renderer IDs, deferred.)

---

## 3. Generated Artifacts (Per Type)

| Symbol | Visibility | Purpose |
|--------|------------|---------|
| `static let __swiftSnapshot_folder: String?` | internal | Holds `folder:` macro argument |
| `static func __swiftSnapshot_makeExpr(_ instance: Self) -> ExprSyntax` | internal | Optimized expression builder |
| `static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata]` | internal | Metadata array (name, rename, redaction, ignored) |
| `public func exportSnapshot(... )` | public | Convenience wrapper around runtime |
| For enums: `static func __swiftSnapshot_caseExpr(_ value: Self) -> ExprSyntax` | internal | Switch-based case dispatcher |

Supporting internal simple types:
```
struct __SwiftSnapshot_PropertyMetadata {
  let original: String
  let renamed: String?
  let redaction: __Redaction?
  let ignored: Bool
}

enum __Redaction {
  case mask(String)
  case hash
  case remove
}
```

---

## 4. Implementation Phases

| Phase | Focus | Outcome |
|-------|-------|---------|
| M0 | Macro target setup & parsing utilities | Compile baseline |
| M1 | Property collection + ordering | Deterministic metadata array |
| M2 | Expression synthesis for structs | Working initializer generation |
| M3 | Property attributes & redaction logic | Mask/hash/remove semantics |
| M4 | Enum support | Case expression builder |
| M5 | Export convenience method | Public ergonomic API |
| M6 | Diagnostics & validation | Developer feedback clarity |
| M7 | Integration tests w/ runtime | End-to-end generation flow |
| M8 | Performance / cleanup | Low overhead code emission |

### Phase Details

#### M0: Setup
- Add `SwiftSnapshotMacro` SPM target
- Depend on `SwiftSyntax` & `SwiftSyntaxMacros`
- Basic `@SwiftSnapshot` that emits no members (compilation sanity)

#### M1: Property Collection
- Use `MemberDeclListSyntax` traversal
- Filter stored properties (variable decl with pattern binding + initializer optional)
- Preserve order as encountered
- Build `__swiftSnapshot_properties`

Tests:
- Mixed stored/computed properties
- Generic type (accept fine, not special-cased)

#### M2: Expression Synthesis (Structs & Classes)
- Generate `Product(id: ..., name: ...)` style initializer
- Use renamed label if provided
- Skip ignored properties
- For removed redaction (.remove) ensure either:
  - Property has default (not always knowable) or produce compile-time diagnostic
- Redacted (mask/hash) replace expression with string literal placeholder (hash defers actual hashing if not accessible—can fallback to `"***"` placeholder now)

Tests:
- Renamed property appears correctly
- Order preserved

#### M3: Redaction & Attribute Semantics
- Parse attribute argument combinations
- Mutual exclusivity validation (mask + hash + remove conflict)
- Apply transformations in expression factory
- Hash Strategy:
  - If `hash: true` and CryptoKit unavailable, fallback to pseudo-hash: stable deterministic SHA256 implementation snippet (optional separate small helper) or simple deterministic hash (document)
- Mask default placeholder `•••` if no `mask` parameter

Tests:
- Each redaction mode
- Invalid combination diagnostics

#### M4: Enum Support
- Confirm declaration is `enum`
- For each `EnumCaseElement`, collect case names + parameter labels
- Generate a switch:
  ```
  switch value {
    case let .caseName(a, b): return ExprSyntax(".caseName(a: \(..), b: \(..))")
  }
  ```
- If label names present, include them; else rely on positional
- Associated value property-level attributes (NOT supported now) – ignore gracefully

Tests:
- Enum without payload
- Enum with labeled/unlabeled payloads
- Mixed cases

#### M5: Convenience Export Method
```
public func exportSnapshot(
  variableName: String? = nil,
  testName: String? = nil,
  header: String? = nil,
  context: String? = nil,
  allowOverwrite: Bool = true,
  line: UInt = #line,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath
) throws -> URL
```
- Computes `varName` fallback (lowerCamelCase of type or file) if nil
- Delegates to runtime using `Self.__swiftSnapshot_folder`
- Passes context: parameter override else macro `context:` literal

Tests:
- Ensures folder hint used
- Overridden context flows through

#### M6: Diagnostics
| Condition | Diagnostic Kind |
|-----------|------------------|
| Invalid attribute target | Warning |
| Conflicting redaction modes | Error |
| Redaction remove causing non-compilable initializer (no default) | Error |
| Enum pattern parse failure | Warning (will reflect at runtime) |
| Rename applied to ignored property | Warning (ignored) |

Add test suite validating messages (string contains key phrase).

#### M7: Integration Tests
- Compose with runtime to export fixture for:
  - Struct with rename + ignore + redaction
  - Enum with associated values
- Parse generated Swift with SwiftSyntax in tests to ensure structural validity
- Snapshot (text) tests for stable code generation

#### M8: Performance & Cleanup
- Ensure macro expansions minimal (avoid unnecessary large string constants)
- Factor helpers to reduce duplicated emitted code
- Document macro attribute usage

---

## 5. Data Flow

1. Developer annotates type with `@SwiftSnapshot`
2. Macro collects metadata & emits:
   - Metadata array
   - Expression builder
   - Export method
3. Runtime `exportSnapshot` call:
   - Detects presence of `__swiftSnapshot_makeExpr`
   - Uses builder to get `ExprSyntax`
   - Applies formatting, header, context
   - Writes file

No reflection used for macro-instrumented fields.

---

## 6. Expression Generation Strategy

| Type Segment | Generation Rule |
|--------------|-----------------|
| Primitive | Inline literal (escaped) |
| Redacted | Replace literal with mask/hash |
| Collection | `[...]` or `Set([...])` recursively calling runtime fallback if unknown |
| Associated Enum | `.caseName(label: subExpr, ...)` |
| Optional | `value` or `nil` |
| Nested Custom Type | Defer to runtime for nested value unless simple (initial version can always defer) |

Optimization (future): Recognize nested annotated types and call their builder directly (not mandatory now).

---

## 7. Testing Matrix (Macro)

| Category | Case |
|----------|------|
| Basic Struct | No attributes |
| Ignore | Single ignored field |
| Rename | Single renamed field |
| Redaction-masked | Mask literal appears |
| Redaction-hash | Hash placeholder appears |
| Redaction-remove | Field omitted |
| Conflicting Redaction | Emits error |
| Enum Simple | No payload cases |
| Enum Associated | Labeled and unlabeled |
| Folder Hint | Affects export path |
| Context | Multi-line doc comment formatting |
| Diagnostics | All defined error/warning conditions |

---

## 8. Acceptance Criteria (Macro)

| Criterion | Definition |
|----------|------------|
| Compile Success | Annotated types compile with generated members |
| Deterministic Output | Rebuild yields identical generated source (hash) |
| Proper Omission | Ignored/removed properties absent in initializer |
| Enum Case Coverage | All declared cases represented in switch |
| Diagnostics Clarity | Conflict errors mention attribute names |
| Interop | Runtime uses macro path without reflection (verified by instrumentation toggle if needed) |

---

## 9. Open Decisions

| Topic | Pending | Default |
|-------|---------|---------|
| Hash Implementation | CryptoKit vs internal | Provide lightweight internal SHA256 impl |
| Redaction on Non-String Types | Cast to string or fallback mask | Convert using `String(describing:)` then mask |
| Automatic variableName inference | Derived from call site? | Caller must supply or use macro convenience default `"fixture"` (explicit for now) |

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Enum Reflection Fallback Complexity | Moderate | Explicit warning; encourage macro annotation |
| Hash Implementation Footprint | Low | Minimal pure Swift digest |
| Large Generated Switch for Huge Enums | Performance | Document; user may trim or segment |
| Attribute Misuse | Developer confusion | Strong diagnostics & README examples |

---

## 11. Deliverables Summary

| Deliverable | Phase |
|-------------|-------|
| Macro infrastructure | M0 |
| Property metadata emission | M1 |
| Struct expression builder | M2 |
| Attribute semantics | M3 |
| Enum builder | M4 |
| Export method | M5 |
| Diagnostics suite | M6 |
| Integration parity tests | M7 |
| Performance pass | M8 |

---

## 12. Immediate Sprint Backlog (Macro)

Sprint A:
- M0, M1, partial M2
Sprint B:
- Finish M2, M3
Sprint C:
- M4–M6
Sprint D:
- M7–M8 polishing

---

## 13. Example (End State)

Input:
```
@SwiftSnapshot(folder: "__Snapshots__/Products", context: "Standard product.")
struct Product {
  let id: String
  @SnapshotRename("displayName")
  let name: String
  @SnapshotRedact(mask: "SECRET")
  let apiKey: String
  @SnapshotIgnore
  let cache: [String: Any]
}
```

Generated (conceptual excerpt):
```
extension Product {
  internal static let __swiftSnapshot_folder: String? = "__Snapshots__/Products"
  internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
    .init(original: "id", renamed: nil, redaction: nil, ignored: false),
    .init(original: "name", renamed: "displayName", redaction: nil, ignored: false),
    .init(original: "apiKey", renamed: nil, redaction: .mask("SECRET"), ignored: false),
    .init(original: "cache", renamed: nil, redaction: nil, ignored: true)
  ]

  internal static func __swiftSnapshot_makeExpr(_ instance: Product) -> ExprSyntax {
    ExprSyntax("Product(id: \(literal(instance.id)), displayName: \(literal(instance.name)), apiKey: \"SECRET\")")
  }
}
```

---

## 14. Documentation Hooks

- Macro README section:
  - Attribute summary table
  - Redaction strategy examples
  - Enum coverage explanation
- Link to library custom renderer guide (integration story)

---
