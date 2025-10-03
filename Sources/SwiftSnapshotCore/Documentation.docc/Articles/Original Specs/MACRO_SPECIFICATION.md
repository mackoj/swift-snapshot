# SwiftSnapshot Macro Specification (macOS-only, Swift-Only Rendering)

Status: Draft  
Depends On: `SwiftSnapshot` runtime library  
Scope: Source macro(s) that synthesize extraction/render metadata and convenience APIs with no separate IR layer.

## 1. Purpose

Enhance determinism and expressiveness by generating compile-time knowledge of:
- Stored properties (ordered)
- Enum cases & associated value labels
- Optional redaction / ignore / rename instructions
- Convenience export method
- Optimized SwiftSyntax expression builder (bypasses reflective heuristics)

## 2. Macro Overview

| Macro | Kind | Effect |
|-------|------|--------|
| `@SwiftSnapshot(folder:context:)` | Type Attribute | Registers the type for snapshot fixture export; generates synthesized members |
| Property-Level: `@SnapshotIgnore` | Attribute | Exclude property from emission |
| Property-Level: `@SnapshotRedact(mask: String? = nil, hash: Bool = false, remove: Bool = false)` | Attribute | Redacts property before emission (mask > hash > remove precedence) |
| Property-Level: `@SnapshotRename("newName")` | Attribute | Changes emitted property label in initializer |
| (Optional extension point) `@SnapshotRendererID("id")` | Attribute | Hint for custom renderer (invoked pre-render; runtime side decides) |

Minimal viable set includes `@SwiftSnapshot` + `@SnapshotIgnore`; others can be added incrementally.

## 3. Generated Members

For a type `T` annotated with `@SwiftSnapshot`:

| Member | Signature | Purpose |
|--------|-----------|---------|
| `static let __swiftSnapshot_properties: [PropertyMetadata]` | Internal | Ordered property metadata (name, renamedName?, redaction strategy, isOptional flag) |
| `static func __swiftSnapshot_makeExpr(from instance: T) -> ExprSyntax` | Internal | Builds SwiftSyntax expression initializer for the instance |
| `func exportSnapshot(variableName:testName:header:context:allowOverwrite:) throws -> URL` | Public convenience | Forwards to runtime export using compiled expression when available |
| (If enum) `static func __swiftSnapshot_caseInfo(of instance: T) -> EnumCaseInfo` | Internal | Describes active case + associated labels recursively |

`PropertyMetadata` and `EnumCaseInfo` are macro-internal support types in a small helper module to avoid IR overhead.

### 3.1 Property Redaction Logic
Applied during `__swiftSnapshot_makeExpr` construction:
- `mask`: Replace string-like property with literal `"•••"` (default mask string if unspecified)
- `hash`: Compute SHA256 hex string and treat as masked string literal (requires import CryptoKit—optional; fallback placeholder if not available)
- `remove`: Omit the argument entirely (skips from initializer argument list)

`@SnapshotIgnore` differs from `remove` in that:
- Ignore: property wholly invisible (not considered missing)
- Remove (redaction): declared property but intentionally omitted—macro chooses ignore-like semantics for initializer if property has default value; else raises compile-time diagnostic (to avoid non-compilable code)

### 3.2 Enum Handling
Macro pattern-matches enum cases:
- Auto-generates a switch inside `__swiftSnapshot_makeExpr`
- For each case with associated values:
  - Captures label list
  - Builds `.caseName(label: valueExpr, ...)` expression
- Redaction/ignore semantics not applied to associated values (unless feasible via attribute annotation on `case` payload patterns—future expansion)

## 4. Diagnostics (Compile-Time)

| Condition | Diagnostic |
|-----------|-----------|
| `@SnapshotRename` applied to non-stored property | Warning (ignored) |
| `@SnapshotRedact(remove: true)` on non-default-initializable property with no alternative initializer path | Error with guidance |
| Multiple redaction flags simultaneously (mask + hash + remove) | Error: “Choose only one redaction mode” |
| `@SnapshotIgnore` on computed property | Warning (redundant) |
| Enum case pattern detection failure | Note suggesting runtime fallback |

## 5. Interaction with Runtime

### 5.1 Expression Bypass
If `__swiftSnapshot_makeExpr` exists, runtime:
1. Uses expression directly to stringify via `SwiftSyntax` printer.
2. Avoids reflection for that subtree.

### 5.2 Partial Extraction (Subclass + Superclass)
- Macro only inspects declared stored properties.
- For classes, runtime may still append reflective rendering for superclass (post-construction) by:
  - Emitting base initializer arguments for subclass fields
  - Appending property assignment syntax for super fields? (Deferred: initial version may not support hybrid class chain; document limitation.)

## 6. Header & Context
- `context:` parameter (if provided) is turned into a triple-slash doc comment block emitted before the `extension <Type>`.
- Header is provided at export call (not macro attribute). Macro does not embed header statically—keeps dynamic flexibility.

## 7. Folder Parameter
`folder:` optional static string; if set:
- Provided to runtime as a preferred base directory unless explicitly overridden by export call.
- Stored in `static let __swiftSnapshot_folder: String?`.

## 8. Macro Parameter Summary

```
@SwiftSnapshot(
  folder: "Fixtures/Users",          // Optional static path (no interpolation)
  context: """
  Premium user baseline fixture.
  Includes elevated permissions.
  """
)
```

Both arguments must be literal expressions (compiler-enforced).

## 9. Implementation Notes

| Concern | Strategy |
|---------|----------|
| SwiftSyntax Version Lock | Use latest stable matching project toolchain; macro minimal API surface |
| Performance | Avoid deep synthesis for nested values; rely on calling into runtime recursion for sub-values unless trivially simple primitives |
| Source Location | `#fileID/#filePath` captured in exported convenience method to preserve path-based root inference |
| Test Discoverability | Add generated symbol names with a stable prefix to ease debugging (`__swiftSnapshot_`) |

## 10. Example Expansion

Source:
```
@SwiftSnapshot(context: "Standard product fixture.")
struct Product {
  let id: String
  @SnapshotRename("displayName")
  let name: String
  @SnapshotIgnore
  let transientCache: [String: Any]
}
```

Generated (conceptual):
```
extension Product {
  internal struct __SwiftSnapshot_PropertyMetadata {
    let original: String
    let renamed: String?
    let redaction: Redaction?
    let ignored: Bool
  }

  internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
    .init(original: "id", renamed: nil, redaction: nil, ignored: false),
    .init(original: "name", renamed: "displayName", redaction: nil, ignored: false),
    .init(original: "transientCache", renamed: nil, redaction: nil, ignored: true)
  ]

  internal static func __swiftSnapshot_makeExpr(from instance: Product) -> ExprSyntax {
    ExprSyntax(
      // Uses renamed label "displayName"
      "Product(id: \(literal(instance.id)), displayName: \(literal(instance.name)))"
    )
  }

  public func exportSnapshot(
    variableName: String? = nil,
    testName: String? = nil,
    header: String? = nil,
    context: String? = nil,
    allowOverwrite: Bool = true,
    line: UInt = #line,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath
  ) throws -> URL {
    try SwiftSnapshotRuntime.export(
      instance: self,
      variableName: variableName ?? "product",
      fileName: nil,
      outputBasePath: Self.__swiftSnapshot_folder,
      allowOverwrite: allowOverwrite,
      header: header,
      context: context ?? """
      Standard product fixture.
      """,
      testName: testName,
      line: line,
      fileID: fileID,
      filePath: filePath
    )
  }

  internal static let __swiftSnapshot_folder: String? = "Fixtures/Users"
}
```

## 11. Redaction Handling (Macro Side)
If a property is marked `@SnapshotRedact(mask:"***")`:
- Macro replaces its expression with a literal `***` (for supported primitive-like types).
- If property type unsupported for inline redaction (e.g. nested struct), macro emits a compile-time warning and defaults to masking via string `"«redacted»"` if convertible; else ignore redaction attribute.

## 12. Limitations (Deliberate for Initial Version)

| Limitation | Rationale |
|------------|-----------|
| Class inheritance hybrid emission | Complexity of bridging initializer vs super reflection; deferred |
| Associated value redaction | Requires pattern match rewriting; deferred |
| Generic type specialization awareness | Macro does not emit specialized permutations; uses runtime recursion |
| Stored property default detection | Not introspected; initializer always supplies explicit arguments |

## 13. Testing Focus (Macro)

| Test Category | Assertions |
|---------------|-----------|
| Ordering | Property order matches source textual order |
| Rename | Emitted initializer uses renamed labels |
| Ignore | Omitted property not referenced |
| Redaction | Mask literal appears; original value absent |
| Enum Case | Switch covers all cases (exhaustive) |
| Diagnostics | Invalid attribute combinations produce errors |
| Folder Parameter | Resolved into export path when not overridden |

## 14. Developer Ergonomics

- Macro attribute deliberately minimal: adding too many switches reintroduces complexity of the removed IR approach.
- Advanced custom rendering (strategy modifications) is handled at runtime via auto-registration.

## 15. Future (Deferred)

| Feature | Potential Direction |
|---------|---------------------|
| Nested Redaction Policies | Per-case for enums |
| Class Super Integration | Partial initializer bridging |
| Enum Payload Transformations | Attributes on associated values |
| Inline Strategy Overrides | `@SnapshotInit(designated:"init(...)")` if runtime reflection insufficient |

---