# SwiftSnapshot Library Implementation Plan (macOS Only, Swift Renderer Only)

Status: Draft  
Scope: Runtime + rendering + configuration + custom renderer auto‑registration + formatting + export pipeline  
Out of Scope: Multi-format outputs, JSON/Markdown, cross-platform, migration adapters, separate IR abstraction

---

## 1. Guiding Constraints

- macOS only (Apple Swift toolchain)
- Single output format: Swift source
- No intermediate IR layer – build `SwiftSyntax` (or string-construction shim) directly
- Deterministic, diff-friendly output
- Pluggable custom renderers via static auto-registration pattern
- Optional global and per-export header strings
- Optional per-type folder hint (provided by macro, but library must accept plain runtime usage)
- Reflection only when macro metadata / custom renderer unavailable
- Minimal public API surface; stable core early

---

## 2. High-Level Phases

| Phase | Focus | Outcome |
|-------|-------|---------|
| L0 | Project scaffolding & core types | Compilable skeleton, config, basic export |
| L1 | Primitive & collection rendering | Stable value → Swift code mapping |
| L2 | Formatting & file emission | Deterministic style + header/context integration |
| L3 | Reflection for structs/classes/enums | General-purpose fallback path |
| L4 | Custom renderer registry + auto-registration helper | Extensible rendering |
| L5 | Enum enhancement & redaction hooks (macro-ready stubs) | Prepared for macro synergy |
| L6 | Determinism hardening & tests (ordering, escaping) | Proven stable output |
| L7 | Performance + concurrency safety | Efficient large-case handling |
| L8 | Documentation & polish | Ready for early adoption |

---

## 3. Detailed Tasks by Phase

### Phase L0: Scaffolding
1. SPM package layout:
   - `Sources/SwiftSnapshot/` (core runtime)
   - `Tests/SwiftSnapshotTests/`
2. Core public API stubs (`SwiftSnapshotRuntime.export`, `.generateSwiftCode`)
3. Config & globals:
   - `SwiftSnapshotConfig` with root + header + format profile placeholders
4. Environment variable handling `SWIFT_SNAPSHOT_ROOT`
5. Basic error enum `SwiftSnapshotError`
6. Simple path resolver (no folder hint yet)
7. Unit tests: configuration precedence sanity

Exit Criteria:
- Can call `generateSwiftCode` on an `Int` and receive a minimal extension fixture string.

### Phase L1: Primitive & Collection Rendering
1. Implement renderer pipeline entry `ValueRenderer.render(any:) -> ExprSyntax (or String)`
2. Primitive mappings:
   - String (escaping), Int, Double (canonical), Bool, Character
3. Foundation basics: Date (`Date(timeIntervalSince1970:)`), UUID (literal string then `UUID(uuidString:)!` or simplified `.init(uuidString:)!`), URL (`URL(string:)!`), Decimal (`Decimal(string: "…")!`), Data (hex ≤ 16 bytes; base64 else)
4. Collections:
   - Arrays (multi-line if >1 element)
   - Dictionaries (string-keyable first; others fallback to unsupported)
   - Sets via `Set([...])`
5. Optionals: `nil` vs nested unwrap
6. Shared helpers:
   - String literal escaper
   - Numeric canonical formatting (avoid scientific unless required)
7. Tests:
   - Escaping edge cases
   - Deterministic ordering (dict keys lexicographically)
   - Data small vs large

Exit Criteria:
- Multi-field struct manually passed through helper renders valid Swift initializer lines (temporary manual path).

### Phase L2: Formatting & File Emission
1. `.swift-snapshot-format` loader (INI-like parsing)
2. `.editorconfig` fallback scan
3. `FormatProfile` application (indent, EOL, trailing newline)
4. Code printer:
   - Multi-line argument lists
   - Trailing commas for >1 element collections / initializer args
5. Header + context injection layering:
   - header parameter > global header > none
   - context doc comment builder (line prefix `///`)
6. Final file write (`allowOverwrite` logic)
7. Tests:
   - Indent size variation
   - EOL normalization (force `\n`)
   - Header inclusion/exclusion

Exit Criteria:
- Exported file with user header + context passes SwiftSyntax parse.

### Phase L3: Reflection Fallback
1. Mirror-based traversal for structs/classes:
   - Extract stored labels & values
2. Enum fallback:
   - RawRepresentable detection
   - Associated values best-effort (`Mirror` children)
3. Heuristics:
   - Attempt single initializer expression `Type(label: value, ...)`
   - If ambiguous or missing labels → fallback sequential member list with labels (if available)
4. Breadth-first path breadcrumb tracking for error context
5. Tests:
   - Nested structs
   - Enum raw / associated
   - Class with stored properties
   - Unsupported types error path accuracy

Exit Criteria:
- Non-macro types produce compiling fixtures for common patterns.

### Phase L4: Custom Renderer Registry & Auto-Registration
1. `SnapshotRendererRegistry`:
   - `register(_:render:)`
   - `renderer(for: Any) -> closure?`
2. Auto-registration convenience:
   - `autoregister(Type.self) { value, ctx in ExprSyntax }` returning `Void`
3. Thread-safety (serial mutation, concurrent reads)
4. Built-in renderer group registration call (`SwiftSnapshotBootstrap.registerDefaults()`)
5. Tests:
   - Override a primitive type (e.g., custom Date style)
   - Ensure user registration supersedes default

Exit Criteria:
- User-defined renderer example test passes & overrides built-in.

### Phase L5: Enum & Redaction Hooks
1. Add lightweight redaction strategy struct (mask/hash/remove) but keep hashing internal (optionally no CryptoKit yet—macro may insert masked literal).
2. Add runtime API hook to accept pre-sanitized value (macro will use later).
3. Improve enum case printing for dot syntax (strip module if simple).
4. Tests:
   - Dot syntax for simple raw case
   - Fallback initializer for ambiguous case
   - Redaction mask applied manually (simulate macro call)

Exit Criteria:
- Redaction scaffolding exists without macro dependency.

### Phase L6: Determinism Hardening
1. Consistent ordering rules:
   - Dictionaries: stable lexicographic by key description
   - Sets: stable by rendered element string
2. Snapshot tests (golden files) for representative models
3. Escaping stress cases: control chars, unicode scalars, emoji sequences
4. Idempotency test: two renders produce identical bytes
5. Optional diff helper in tests for failure diagnostics

Exit Criteria:
- All determinism tests green; no flakiness over 10 repeated runs.

### Phase L7: Performance & Concurrency
1. Micro-bench harness (not public):
   - Large array (10k Int)
   - Nested dictionary depth test
2. Optimize:
   - Preallocate string builders
   - Avoid dynamic casting loops
3. Concurrency:
   - Run N (e.g., 50) parallel exports; ensure no race (TSan pass)
4. Document basic performance metrics in test logs

Exit Criteria:
- Benchmarks within tolerance (define ceiling, e.g., large array render < 1s).

### Phase L8: Documentation & Polish
1. README Quick Start (runtime only)
2. Custom renderer guide with auto-registration example
3. Formatting config doc
4. Header usage examples
5. Troubleshooting matrix (common errors: unsupported type, overwrite blocked)
6. API symbol doc comments audit

Exit Criteria:
- All public APIs documented; examples compile in DocC tests (optional).

---

## 4. Data Structures & Key APIs

### 4.1 Config
```
public enum SwiftSnapshotConfig {
  static func setGlobalRoot(_:)
  static func getGlobalRoot() -> URL?
  static func setGlobalHeader(_:)
  static func getGlobalHeader() -> String?
  static func setFormattingProfile(_:)
  static func formattingProfile() -> FormatProfile
  static func setRenderOptions(_:)
  static func renderOptions() -> RenderOptions
}
```

### 4.2 RenderOptions
```
public struct RenderOptions {
  var sortDictionaryKeys: Bool = true
  var setDeterminism: Bool = true
  var dataInlineThreshold: Int = 16
  var forceEnumDotSyntax: Bool = true
}
```

### 4.3 Error Enum
```
public enum SwiftSnapshotError: Error {
  case unsupportedType(String, path: [String])
  case io(String)
  case overwriteDisallowed(URL)
  case reflection(String, path: [String])
  case formatting(String)
}
```

---

## 5. Testing Matrix (Library)

| Category | Tests |
|----------|-------|
| Primitives | All literal forms + numeric edge cases (0, -1, large) |
| Strings | Escaping quotes, backslashes, unicode scalar, emoji |
| Collections | Nested arrays/dicts/sets, empty cases |
| Optionals | nil, nested optionals (T??) collapse correctness |
| Dates/Data | Threshold switching for Data; exact epoch double |
| Enums | Raw and associated, unknown fallback |
| Classes | Reflection order stability (document any caveats) |
| Custom Renderer | Override Date style; ensure usage |
| Redaction Hook | Manual injection yields masked literal |
| Determinism | Repeat renders identical (hash compare) |
| Performance | Benchmark asserts under threshold |
| Concurrency | Thread safety (parallel exports) |
| Formatting | Indent variation, trailing newline |
| Headers | Global vs per-export precedence |

---

## 6. Acceptance Criteria (Library)

| Criterion | Definition of Done |
|-----------|-------------------|
| Compilable Output | All generated fixtures parse with SwiftSyntax |
| Deterministic | Hash identical across three consecutive runs for same input |
| Extensibility | User-provided custom renderer test passes |
| Error Clarity | Unsupported type includes breadcrumb path |
| Reflection Reliability | Typical Swift domain models (structs/enums) render without manual hints |
| Performance | 10k Int array fixture < defined threshold (e.g., 750ms release build) |
| Formatting | Indentation & newline rules obey config |
| Header Support | Global + per-export layering works as specified |

---

## 7. Open Decisions

| Topic | Pending Decision | Default Assumption |
|-------|------------------|--------------------|
| UUID rendering style | `.init(uuidString:)!` vs custom parse | Use `UUID(uuidString:)!` |
| Decimal precision strategy | Preserve `description` | Use `description` directly |
| Large double formatting | Avoid scientific unless needed | Use `String(format:"%.15g", value)` |
| Optional chained properties formatting | Inline vs multiline | Inline unless nested initializer > 80 chars |

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Reflection property order variance | Moderate | Document; macro path preferred for strict order |
| Large memory usage on huge graphs | Performance | Stream building + avoid deep recursion for arrays |
| Custom renderer collisions | Low | Last registration wins (document) |
| Enum associated labeling via Mirror unreliable | Low | Encourage macro for enums in docs |

---

## 9. Immediate Sprint Backlog (First Two Sprints)

Sprint 1:
- L0 + partial L1 (primitives)
- Basic tests + CI pipeline
Sprint 2:
- Complete L1 (collections, optionals)
- L2 formatting + file emission
- Start reflection (L3 skeleton)

---

## 10. Deliverables Summary

| Artifact | Phase |
|----------|-------|
| Public API (export / config) | L0 |
| Primitive + collection renderer | L1 |
| Formatter & file writer | L2 |
| Reflection fallback | L3 |
| Custom renderer registry | L4 |
| Enum enhancement & redaction hook | L5 |
| Determinism suite | L6 |
| Benchmarks & concurrency tests | L7 |
| Documentation set | L8 |

---