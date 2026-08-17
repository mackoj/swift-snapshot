# Testing Strategy

SwiftSnapshot has different reliability layers.
They are tested differently on purpose.

## 1. Deterministic core (blocking)

These tests define stable behavior.
They must pass in normal CI.

- Rendering primitives and collections
- Reflection-based struct and enum rendering
- Deterministic ordering and identifier sanitization
- Config, formatting profile loading, and path resolution
- File export behavior

Current suites:

- `SwiftSnapshotTests/SwiftSnapshotTests.swift`
- `SwiftSnapshotTests/IntegrationTests.swift`
- `SwiftSnapshotTests/ReproductionTests.swift`
- `SwiftSnapshotTests/GenericCollectionTests.swift`
- `SwiftSnapshotTests/IntegerTypesTests.swift`
- `SwiftSnapshotTests/GeneratedCodeValidityTests.swift`
- `SwiftSnapshotTests/VariableNameSanitizationTests.swift`
- `SwiftSnapshotTests/RenderOptionsTests.swift`
- `SwiftSnapshotTests/FormattingConfigTests.swift`
- `SwiftSnapshotTests/SwiftSnapshotConfigTests.swift`
- `SwiftSnapshotTests/SnapshotRenderContextTests.swift`
- `SwiftSnapshotTests/SnapshotRendererRegistryTests.swift`
- `SwiftSnapshotTests/PathResolverTests.swift`
- `SwiftSnapshotTests/DependencyInjectionTests.swift`
- `SwiftSnapshotTests/SwiftSnapshotErrorTests.swift`
- `SwiftSnapshotTests/EditorConfigIntegrationTests.swift`

## 2. Macro expansion behavior (separate layer)

Macro tests validate generated declarations and annotations.
They are not the same as runtime reflection correctness.

Current suites:

- `SwiftSnapshotMacrosTests/SwiftSnapshotMacrosTests.swift`
- `SwiftSnapshotMacrosTests/IntegrationTests.swift`

These tests use `MacroTesting` and snapshot-style assertions similar to pointfreeco/swift-macro-testing.

## 3. Performance characterization (non-blocking signal)

Performance tests detect regressions.
They should inform decisions, not hide correctness failures.

Current suite:

- `SwiftSnapshotTests/PerformanceTests.swift`

## 4. Manual verification (not part of CI guarantees)

Manual checks stay isolated.
They are useful during development, but they do not define stability guarantees.

Current file:

- `SwiftSnapshotTests/ManualSanitizationVerification.swift`

## Baseline commands

Run runtime/core tests:

```bash
swift test --filter SwiftSnapshotTests
```

Run macro tests:

```bash
swift test --filter SwiftSnapshotMacrosTests
```
