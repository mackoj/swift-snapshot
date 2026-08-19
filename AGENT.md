# AGENT.md

Instructions for coding agents working in this repository.

The shared baseline is
[dktunited/swift-shared-agent](https://github.com/dktunited/swift-shared-agent). The parts
that apply here are inlined below. Where this file and the shared one disagree, this file
wins.

## What this package is

SwiftLiteral turns a runtime value into Swift source that rebuilds it. The output is a
`.swift` file you commit.

The whole point is that the output compiles. A fixture that parses but does not build is
worse than no fixture, so the library throws rather than guess.

## Voice

For every README, article, doc comment, and commit message.

- **Certain, unhurried, slightly bored of being right.** The certainty comes from a
  question already settled elsewhere, not from insistence. Never sound like you are winning
  an argument.
- **Say the thing, then explain it.** No warm-up. No throat-clearing.
- **Short sentences. One idea each.** If a paragraph can be a sentence, it is a sentence.
- **Assert rules, observe people.** Be unhedged about technical claims. Never pronounce on
  someone else's situation, team, or codebase. You do not know it.
- **Every claim carries its cost.** Do not recommend anything without naming what it is
  worse at.
- **Avoid** enthusiasm, exclamation, "powerful", "elegant", stacked parallel clauses,
  em-dash triplets, "not X but Y" as a reflex, and summary sentences that restate the
  paragraph above.
- **Length is the failure mode.** Cut, then cut again.

Cost of this voice: it reads cold. That is the trade. A reader skimming for reassurance
will not find any.

## Clarity

Documentation is read by someone who is tired and looking for one thing.

- Lead with the action. Code first, prose after.
- Number anything with more than one step. One bounded action per step.
- Cap a list at five items. If it grows past five, split it into "do now" and "later".
- Name the concrete next thing at the end of a section.
- State the cause and the fix for every error. Never "something went wrong".

## How to work

**YAGNI.** Write the minimum that solves the problem. No abstraction for a single use. No
configuration knob nobody asked for. If a solution is 200 lines and could be 50, rewrite
it.

**Surgical changes.** Touch what the task needs. Do not reformat adjacent code or refactor
things that are not broken. Remove orphans your change creates; leave pre-existing dead
code alone and mention it.

**Say what is ambiguous.** If two readings exist, name both. Do not paper over uncertainty
with code.

**Verify, do not assume.** Run the thing. Two bugs in this repository were found by
checking a claim that looked obviously true.

## Build and test

```bash
xcrun swift build
xcrun swift test
xcrun swift test --filter <SuiteName>
```

**Use `xcrun`.** A bare `swift` picks up a standalone swiftly toolchain, which cannot build
swift-dependencies: `external macro implementation type 'SwiftUIMacros.EntryMacro' could
not be found`. CI is unaffected, because `swift` is Xcode's there after `xcode-select`.

Documentation is part of the build:

```bash
xcrun swift package generate-documentation --target SwiftLiteralCore --warnings-as-errors
```

## Design rules

**Compile-time over runtime.** Ask whether the compiler can enforce a rule instead of a
test or a comment. Prefer `throws` with typed errors over optional returns that hide the
reason. Prefer a type wrapper over a convention.

**Errors, not silence.** Never substitute a placeholder for a value that failed to render.
A wrong file that looks right is the failure this library exists to prevent.

**Swift 6 strict concurrency**, enforced package-wide. Public closures are `@Sendable`.

**No globals below the entry point.** The engine reads no process state. Everything arrives
in a `RenderContext`. Configuration is resolved once, at the top of a render.

`LiteralConfig` is the exception, and it is deliberate: an app configures the library once
at launch, so a process-global holder is the right shape. It is behind an `NSLock` rather
than an actor because the API is synchronous and making it async would change every call
site. Tests do not read it. They read `LiteralConfigurationClient`, whose test value is the
library defaults.

**Fear singletons.** One was removed from this package after it caused a test to pass five
times locally and fail on the first CI run. Global mutable state shared between tests is
the bug, not the symptom.

## Testing rules

Swift Testing. `@Test`, `@Suite`, `#expect`. Not XCTest.

**The test that matters is `everySampleTypechecks`.** It renders the whole sample matrix,
writes it next to the real type declarations, and runs `swiftc -typecheck` over both.
Parsing is not enough: `User(name: nil)` parses.

To add a case:

1. Add the type to `Tests/SwiftLiteralReflectionTests/Models.swift`, at file scope.
2. Add a `Sample` to `Tests/SwiftLiteralReflectionTests/Samples.swift`.
3. Delete `__Snapshots__/RoundTripTypecheckTests/everySampleTypechecks.fixtures.txt`.
4. Run the test twice. The first run records, the second asserts.

**Tests must not share state.** Every test brings its own. A suite that only passes in one
order has coupling that will fail on CI.

To scope configuration:

```swift
withDependencies {
  $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
} operation: {
  try Literal.source(of: value, named: "fixture")
}
```

Four suites test the global pathway itself and opt back in with
`@Suite(.dependency(\.literalConfiguration, .live))`. Do not add a fifth without a reason.

## Documentation rule

**Bad documentation is worse than none.**

When you change a type, an API, a behaviour, or the file layout, update every document that
describes it. Check `README.md` and `Sources/*/Documentation.docc/`.

```bash
grep -rn "SymbolName" README.md Sources/*/Documentation.docc/
```

Do not document a parameter whose name and type already say it. Document why, and document
constraints that are not obvious.

## Things that will waste your time

**Inline snapshots do not re-record here.** `assertInlineSnapshot` reports the diff and
claims it recorded, and the file is unchanged. Copy the expected text in by hand. File
snapshots under `__Snapshots__` do re-record: delete the file and run twice.

**Cross-module DocC links fail on some toolchains.** A ` ``Symbol`` ` in `SwiftLiteralCore`
naming a `SwiftLiteralReflection` type resolves on Swift 6.4 and fails on CI. Use a code
span. `DocLinkTests` catches it in milliseconds, so run the tests before pushing a doc
change.

**`reportIssue` is a test failure, not a logger.** It used to be called on every render.
Any user exporting a fixture inside a test got spurious failures, and on one toolchain it
segfaulted the process.

**`Mirror` stops at the class it was made from.** Walk `superclassMirror` or a subclass
silently loses its inherited state.

**`String(describing:)` gives a nested type its short name.** `Order.Line` becomes `Line`,
which does not resolve from a fixture in an extension on something else.

**Squash merges make stacked branches conflict.** When a PR below yours lands, merge `main`
in and expect conflicts in every file both touched. Yours is usually the superset. Verify
by running the round-trip test, not by reading the diff.
