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

## Reset

```swift
LiteralConfig.resetToLibraryDefaults()
```

Configuration is global, so a test that changes it changes it for whatever runs next. Reset
in your suite's `init`.
