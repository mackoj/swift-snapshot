# Formatting

Generated files go through swift-format. Point it at your project's config and the
fixtures come out looking like the rest of your code.

## Why it matters

A fixture is a file you read in a pull request. If it is indented differently from every
other file in the repository, the diff is about whitespace instead of about the data.

## From .editorconfig

```swift
LiteralConfig.setFormatConfigSource(.editorconfig(URL(filePath: ".editorconfig")))
```

Read from the `[*.swift]` section, falling back to `[*]`:

| `.editorconfig` | ``FormatProfile`` |
|---|---|
| `indent_style = space \| tab` | `indentStyle` |
| `indent_size` | `indentSize` |
| `end_of_line = lf \| crlf` | `endOfLine` |
| `insert_final_newline` | `insertFinalNewline` |
| `trim_trailing_whitespace` | `trimTrailingWhitespace` |

A `[*.swift]` section wins over `[*]`. Anything not set keeps the library default.

Keys `.editorconfig` defines that have no effect here — `charset`, `max_line_length`,
`tab_width` — are read and ignored.

## From .swift-format

```swift
LiteralConfig.setFormatConfigSource(.swiftFormat(URL(filePath: ".swift-format")))
```

Reads `indentation.spaces`, or `indent`, or `tabWidth`, in that order. swift-format's
config has nothing to say about line endings or trailing whitespace, so those keep the
library defaults.

Pick one source or the other. Setting both is not a merge, it is a coin toss.

## Directly

```swift
LiteralConfig.setFormattingProfile(
    FormatProfile(indentStyle: .space, indentSize: 2)
)
```

## Defaults

Four spaces. LF. Final newline. No trailing whitespace.

```swift
FormatProfile.default
```

## In tests

``LiteralConfig`` is process-global. In an app that is fine. In a test suite it is not:
tests run concurrently, so one test setting a two-space `.editorconfig` changes what
another test renders, and the failure is timing-dependent. It passes on your machine and
fails on CI.

So a render does not read the globals in tests. It reads
``LiteralConfigurationClient``, whose test value is the library defaults and nothing else.
Four spaces, deterministic ordering, no global root, whatever any other test is doing.

To render with something else, say so:

```swift
withDependencies {
  $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
} operation: {
  let code = try Literal.source(of: value, named: "fixture")
}
```

The override lives in a task local, so it applies to that test and no other.

To test the global pathway itself, opt the suite back into the live client:

```swift
@Suite(.dependency(\.literalConfiguration, .live))
struct MyConfigTests { … }
```

## Reset

```swift
LiteralConfig.resetToLibraryDefaults()
```

For an app that configured the library at launch and wants to undo it.
