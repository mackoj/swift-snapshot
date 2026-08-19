# Progress log

Append-only. Newest at the bottom. Written so no work gets redone.

## 2026-08-19 — survey

Read the whole source tree. Ran the suite.

**`swift test` segfaults on `main`.** Not a flake, deterministic. Crash is in
`targetLevelReflectionExtractionAppliesRedaction`, the test added by the most recent
commit (#46). Stack: `generateSwiftCode` -> `@Dependency(\.swiftSnapshotConfig)` ->
swift-dependencies `CachedValues.CacheKey.init` -> swift-testing `_currentTest()` ->
`EXC_BAD_ACCESS` in `outlined destroy of Test?`.

Also checked: `swift package update` does not fix it. Latest swift-snapshot-testing (1.19.4)
does not compile against the 6.3.3 toolchain at all (`Attachment` requires `Data: Attachable`).
Dependencies need pinning, not bumping.

Everything else is in PLAN.md.
