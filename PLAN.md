# SwiftSnapshot Progressive Plan
## Goal
Make the project easier to trust and easier to understand.
Do it in this order: test coverage, isolation/deprecation, docs/story.
## Phase 1 — Testing baseline first
1. Freeze current behavior with executable tests.
2. Classify tests by reliability layer:
    - deterministic core
    - macro expansion layer
    - performance signal
    - manual verification
3. Keep snapshot assertions readable and diff-friendly.
4. Add targeted reflection edge-case tests:
    - optionals
    - nested generics
    - enum payloads
    - dictionaries with deterministic ordering
    - collection edge-cases
Status:
- Added `TESTING.md` with this matrix and baseline commands.
## Phase 2 — Isolate weak surfaces
1. Keep reflection/built-ins as the stable default path.
2. Treat macro expression-string rendering as experimental/opt-in only.
3. Deprecate APIs that encourage dependence on unstable rendering internals.
4. If needed, split reflection engine into a dedicated target boundary:
    - `SwiftSnapshotCore` for runtime API + formatting + export flow
    - `SwiftSnapshotReflection` for reflection details and tests
## Phase 3 — Reflection quality pass
1. Compare behavior with pointfreeco/swift-debug-snapshots where useful.
2. Borrow test cases and engine ideas that improve determinism/correctness.
3. Add regression tests before changing behavior.
## Phase 4 — Documentation and README rewrite
Voice:
- certain
- unhurried
- direct
- short sentences
- no hype
Structure:
1. What it is
2. Why Swift fixtures instead of JSON
3. How it works
4. Guarantees
5. Limits
6. Where it fits
## Current blockers
- Local SwiftPM test runtime crash (signal 11) in `swiftpm-testing-helper`.
- This blocks complete test verification in current environment.