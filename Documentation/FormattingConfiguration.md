# Formatting Configuration

SwiftSnapshot supports configurable code formatting through `.editorconfig` or `.swift-format` files.

## Configuration Sources

You can specify the format configuration source using `SwiftSnapshotConfig`:

```swift
// Use .editorconfig file
let editorconfigURL = URL(fileURLWithPath: "/path/to/project/.editorconfig")
SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(editorconfigURL))

// Use .swift-format file
let swiftFormatURL = URL(fileURLWithPath: "/path/to/project/.swift-format")
SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(swiftFormatURL))
```

## .editorconfig Format

SwiftSnapshot supports the following `.editorconfig` properties:

```ini
[*]
indent_style = space
indent_size = 4
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
```

### Supported Properties

| Property | Values | Default | Description |
|----------|--------|---------|-------------|
| `indent_style` | `space` | `space` | Indentation style (only spaces supported) |
| `indent_size` | `1-8` | `4` | Number of spaces per indent level |
| `end_of_line` | `lf`, `crlf` | `lf` | Line ending style |
| `insert_final_newline` | `true`, `false` | `true` | Insert newline at end of file |
| `trim_trailing_whitespace` | `true`, `false` | `true` | Remove trailing whitespace |

## Default Configuration

If no configuration is specified, SwiftSnapshot uses these defaults:

- Indent style: `space`
- Indent size: `4` spaces
- End of line: `lf` (line feed)
- Insert final newline: `true`
- Trim trailing whitespace: `true`
