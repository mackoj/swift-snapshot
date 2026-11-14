# Measuring and profiling

The benchmarks live in `Benchmarks/`, a separate package on [package-benchmark](https://github.com/ordo-one/benchmark),
so the library never depends on it. Run everything from the repository root.

## What is measured

| Benchmark | Path |
|---|---|
| `Render, 1000 orders` | `ValueRenderer.render` over an array of structs with enums, optionals, sets, `UUID`, `Date`, `Decimal` |
| `Render, dictionary of 1000 orders` | The same orders under `String` keys |
| `Render, 10000 integers` | A flat array, the per-element floor |
| `Render, 2000 strings with escapes` | Quotes, tabs, newlines, accents and emoji |
| `Render, enum tree 40 deep`, `Render, class chain 40 deep` | Deep nesting: an indirect enum and a linked list of classes |
| `Source, one order`, `Source, 1000 orders` | `Literal.source`: render, build the file, swift-format, post-process |

Each reports wall clock, CPU, mallocs, peak resident memory and retains.

## Measure a change

Save `main`'s numbers before you change code, then compare the same harness after:

```sh
swift package --package-path Benchmarks benchmark --format markdown --no-progress > .build/before.md
# … change the code …
swift package --package-path Benchmarks benchmark --format markdown --no-progress > .build/after.md
swift run --package-path Benchmarks -c release p50 .build/before.md .build/after.md
```

`p50` prints each benchmark's median wall clock and mallocs, before → after, as a Markdown table. Malloc counts are
deterministic. Wall clock moves between runs, more so on a machine doing anything else, so rerun before trusting a
small change.

- `--filter` takes a regular expression that must match the whole name: `--filter 'Render.*'`, not `--filter Render`.
- CI builds the benchmarks and does not run them. Shared runners are too noisy for numbers.

## Profile a benchmark

```sh
Benchmarks/scripts/profile.sh 'Render, 1000 orders' 30
```

It runs that one benchmark under Instruments' Time Profiler and prints:

- **Self**: the functions the samples were in. `tryCast` and `swift_conformsToProtocol…` are `as?` casts from `Any`;
  `Lexer.Cursor…` is SwiftParser; `_xzm_malloc` is allocation.
- **Inclusive**: the renderer, formatter and swift-syntax functions with the most samples under them.

The trace stays in `Benchmarks/.build/profiles/` to open in Instruments.

## Where the time goes

- **Rendering** is about 60% reflection (`Mirror`, the cast chain in `ValueRenderer.text`) and 40% parsing the
  rendered text back, which is how the renderer proves the output is an expression. The parse is the guarantee, not
  overhead to remove.
- **`Literal.source`** is mostly swift-format: its rule pipeline, its pretty printer, and a parse of the file it does
  itself to build a location converter. A one-value fixture costs a couple of milliseconds, nearly all of it there.

## What has paid off

PLACEHOLDER_TABLE

- **One `Mirror` per value.** `collectionText`, `rangeText` and `reflectedText` each built their own, so every struct
  paid three times.
- **Cheap checks before expensive ones.** Every struct went through `rangeText`, which built a type name with
  `String(describing:)` before looking at the labels. The labels come first now.
- **Cache type names per render.** `String(reflecting:)` and a split, for every struct and enum value, for a handful
  of distinct types. The cache lives in `RenderContext`, so nothing outlives the render.
- **Escape by Unicode scalar, not `Character`.** Grapheme breaking was the largest cost of rendering text.
- **Build the error path only on error.** The breadcrumb path was a new array per value; it is a chain now, turned into
  `[String]` when an error reads it.
- **No `BasicFormat` pass before swift-format.** swift-format prints the tree it is given; the formatted text only fed
  its location converter.
- **No regular expression per line** when trimming trailing whitespace.

## Limits

- **Nesting depth.** Rendering and parsing both recurse once per level of nesting. On a thread with a 512 KB stack,
  which is what a secondary thread and a Swift Testing test get, about 50 levels overflows it in a debug build and
  about 100 in a release build, inside SwiftParser. The main thread's 8 MB goes much further. Render deep values on the main
  thread, or on a thread created with a larger stack.
