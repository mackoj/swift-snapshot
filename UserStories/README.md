# SwiftSnapshot – User Stories

Track the implementation progress of all planned improvements.

---

## Epic A · Correctness Fixes

Bugs where the renderer produces wrong output or noisy side-effects.

- [x] [US-1](US-1-remove-debug-noise.md) **Remove debug noise** — `reportIssue` is called on every successful struct/Optional render, polluting test output with spurious failures.
- [ ] [US-2](US-2-dictionary-key-type-preservation.md) **Dictionary key type preservation** — `[Int: String]` renders as `["1": "one"]` instead of `[1: "one"]`; the generated code doesn't compile.

---

## Epic B · Type Coverage

Types that are unsupported or handled incorrectly by the renderer.

- [ ] [US-3](US-3-range-type-support.md) **Range & ClosedRange support** — `1..<5` and `1...5` fall through to Collection rendering and produce invalid Swift output.
- [ ] [US-6](US-6-result-type-support.md) **`Result<Success, Failure>` support** — `Result` falls through to reflection and produces internal storage output.

---

## Epic C · Safety & Robustness

Behaviours that can crash or produce non-deterministic output under real-world conditions.

- [ ] [US-4](US-4-circular-reference-detection.md) **Circular reference detection** — Class instances that reference themselves cause infinite recursion.
- [ ] [US-5](US-5-set-determinism.md) **Deterministic Set ordering** — Sets are sorted lexicographically on the string representation, giving wrong numeric order (`"10" < "2"`).
