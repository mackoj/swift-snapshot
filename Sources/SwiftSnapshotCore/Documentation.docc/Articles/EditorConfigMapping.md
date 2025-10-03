# EditorConfig to swift-format Mapping

This document describes how EditorConfig properties are mapped to swift-format configuration and post-processing in SwiftSnapshot.

## Overview

SwiftSnapshot uses a two-stage approach to apply EditorConfig settings:
1. **swift-format stage**: Properties that swift-format can handle are converted to swift-format configuration
2. **Post-processing stage**: Properties not natively supported by swift-format are applied as post-processing

## Property Mapping Table

| EditorConfig Property | swift-format Support | Implementation | Notes |
|----------------------|---------------------|----------------|-------|
| `indent_style` | ✅ Yes | `Configuration.indentation` | Mapped to `.spaces(n)` or `.tabs(n)` |
| `indent_size` | ✅ Yes | `Configuration.indentation` | Used as parameter to `.spaces(n)` or `.tabs(n)` |
| `end_of_line` | ❌ No | Post-processing | Applied after swift-format by replacing line endings |
| `insert_final_newline` | ❌ No | Post-processing | Applied after swift-format by adding/removing final newline |
| `trim_trailing_whitespace` | ❌ No | Post-processing | Applied after swift-format by trimming each line |

## swift-format Native Support

### indent_style and indent_size

These properties are directly supported by swift-format's `Configuration.indentation` property:

```swift
// EditorConfig:
// indent_style = space
// indent_size = 4

// Mapped to swift-format:
var configuration = SwiftFormat.Configuration()
configuration.indentation = .spaces(4)
```

```swift
// EditorConfig:
// indent_style = tab
// indent_size = 2

// Mapped to swift-format:
var configuration = SwiftFormat.Configuration()
configuration.indentation = .tabs(2)
```

**Implementation:** `CodeFormatter.configurationFromProfile(_:)`

## Post-Processing

The following properties are not natively supported by swift-format and are applied as post-processing after swift-format runs.

### trim_trailing_whitespace

**Purpose:** Removes trailing spaces and tabs from the end of each line.

**Implementation:**
- Splits code into lines
- Uses regex to remove trailing whitespace: `[ \\t]+$`
- Joins lines back together

**Function:** `CodeFormatter.trimTrailingWhitespace(_:)`

**Example:**
```swift
// Before post-processing:
let value = 42   \n

// After post-processing (trim_trailing_whitespace = true):
let value = 42\n
```

### end_of_line

**Purpose:** Converts line endings to the specified format (LF or CRLF).

**Implementation:**
- First normalizes all line endings to LF (`\n`)
- If CRLF is requested, replaces all LF with CRLF (`\r\n`)
- Applied after trimming whitespace and final newline handling

**Function:** `CodeFormatter.applyEditorConfigPostProcessing(_:profile:)`

**Example:**
```swift
// EditorConfig:
// end_of_line = lf
// Result: Lines end with \n

// EditorConfig:
// end_of_line = crlf
// Result: Lines end with \r\n
```

### insert_final_newline

**Purpose:** Ensures the file ends with exactly one newline (or no newline if `false`).

**Implementation:**
- Removes all trailing newlines
- If `true`, adds exactly one newline
- Applied before line ending conversion (uses LF temporarily, then converted to desired style)

**Function:** `CodeFormatter.applyFinalNewline(_:insert:lineEnding:)`

**Example:**
```swift
// EditorConfig:
// insert_final_newline = true
// Result: File ends with exactly one newline

// EditorConfig:
// insert_final_newline = false
// Result: File ends without a newline
```

## Processing Order

The post-processing is applied in the following order:

1. **Normalize line endings to LF** - Ensures consistent processing
2. **Trim trailing whitespace** - Applied to each line
3. **Apply final newline** - Add or remove final newline (using LF)
4. **Convert line endings** - Convert to target style (LF or CRLF)

This order ensures that:
- Trailing whitespace is properly trimmed regardless of original line endings
- Final newline handling works consistently
- Line ending conversion is the last step, converting everything including the final newline

## EditorConfig Section Resolution for Swift Files

SwiftSnapshot resolves EditorConfig properties for Swift files by processing sections in order:

1. Properties before any `[section]` header (applies to all files, including Swift)
2. Properties in `[*]` section (applies to all files)
3. Properties in `[*.swift]` section (applies specifically to Swift files)

Later sections override earlier sections for matching properties. All three types of sections are accumulated when building the final configuration for Swift files.

### Example

```ini
# Default section (applies to all files)
indent_style = tab
end_of_line = lf

[*]
indent_style = space
indent_size = 2

[*.swift]
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true
```

**Resolved for Swift files:**
- `indent_style` = `space` (from `[*]`, overriding default section)
- `indent_size` = `4` (from `[*.swift]`, overriding `[*]`)
- `end_of_line` = `lf` (from default section, no later section overrides it)
- `insert_final_newline` = `true` (from `[*.swift]`)
- `trim_trailing_whitespace` = `true` (from `[*.swift]`)

## Library Defaults

If no EditorConfig file is specified, SwiftSnapshot uses these defaults:

| Property | Default Value |
|----------|--------------|
| `indent_style` | `space` |
| `indent_size` | `4` |
| `end_of_line` | `lf` |
| `insert_final_newline` | `true` |
| `trim_trailing_whitespace` | `true` |

## Limitations

### Properties Not Currently Handled

The following standard EditorConfig properties are not currently supported:

- `charset` - SwiftSnapshot always uses UTF-8
- `max_line_length` - Not enforced (swift-format has its own line length setting)
- `tab_width` - Not applicable (we use indent_size for both spaces and tabs)

### Tab Support

While `indent_style = tab` is supported in the configuration, swift-format may still use spaces in some contexts (e.g., alignment). This is a limitation of swift-format itself.

## Testing

Comprehensive tests for EditorConfig behavior can be found in:
- `Tests/SwiftSnapshotTests/EditorConfigIntegrationTests.swift`

These tests verify:
- Section resolution ([*], [*.swift])
- Property precedence
- Post-processing correctness
- Edge cases
