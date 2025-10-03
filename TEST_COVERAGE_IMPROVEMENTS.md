# Test Coverage Improvements

## Summary

This PR significantly improves test coverage for the swift-snapshot library by adding comprehensive tests for previously untested or poorly tested components.

## Test Statistics

- **Before**: 98 tests
- **After**: 174 tests
- **Added**: 76 new tests (+77.6% increase)

## New Test Files Created

### 1. PathResolverTests.swift (8 tests)
Tests for the `PathResolver` enum which handles snapshot file path resolution.

Coverage includes:
- Output directory resolution with explicit path
- Output directory resolution with global configuration
- Output directory resolution with environment variable
- Output directory resolution with default behavior
- File path resolution with custom filename
- File path resolution with default filename
- Various type and variable name combinations
- Priority order testing (explicit > global > env > default)

### 2. RenderOptionsTests.swift (11 tests)
Tests for `RenderOptions` struct and `FormatProfile` struct including their nested enums.

Coverage includes:
- RenderOptions initialization and property mutation
- FormatProfile initialization with all properties
- IndentStyle enum (space/tab)
- EndOfLine enum (lf/crlf) and string conversion
- indent() method with various levels and sizes
- Property mutation tests

### 3. SwiftSnapshotErrorTests.swift (10 tests)
Tests for all `SwiftSnapshotError` enum cases.

Coverage includes:
- unsupportedType error with and without path
- io error
- overwriteDisallowed error
- formatting error
- reflection error with and without path
- Error catching and matching
- Error description formatting
- Complex path handling

### 4. SnapshotRenderContextTests.swift (12 tests)
Tests for `SnapshotRenderContext` struct.

Coverage includes:
- Default initialization
- Initialization with custom path, formatting, and options
- Path appending functionality
- Multiple sequential appends
- Property preservation during append
- Dependency injection integration
- Special characters in paths

### 5. SnapshotRendererRegistryTests.swift (9 tests)
Tests for `SnapshotRendererRegistry` class and related functionality.

Coverage includes:
- Custom renderer registration
- Multiple renderer registration
- Renderer overwriting
- Unregistered type handling
- Error handling for wrong types
- Context usage in renderers
- Protocol-based renderer registration
- Thread safety
- SwiftSnapshotBootstrap functionality

### 6. SwiftSnapshotConfigTests.swift (20 tests)
Tests for `SwiftSnapshotConfig` enum and configuration management.

Coverage includes:
- Global root setting/getting/clearing
- Global header setting/getting/clearing (including multiline)
- Formatting profile setting/getting
- Render options setting/getting
- Format config source setting/getting/clearing (editorconfig and swift-format)
- Reset to library defaults
- Library default methods
- Immutability of library defaults
- Thread safety
- FormatConfigSource enum cases

## Enhanced Test Files

### FormattingConfigTests.swift (+11 tests, now 17 total)
Enhanced existing tests with additional coverage for `FormatConfigLoader`.

New tests added:
- findConfigFile when file doesn't exist
- EditorConfig with tab indent style
- EditorConfig with CRLF line endings
- EditorConfig with false boolean flags
- EditorConfig with section matching
- EditorConfig with comments
- SwiftFormat with indent field
- SwiftFormat with tabWidth field
- SwiftFormat with invalid JSON
- SwiftFormat with non-dictionary JSON
- loadProfile with nil source

## Components Now Fully Tested

1. **PathResolver** - Previously untested, now has 8 comprehensive tests
2. **RenderOptions** - Previously only used in integration tests, now has dedicated unit tests
3. **FormatProfile** - Previously only used in integration tests, now has dedicated unit tests
4. **FormatConfigLoader.loadFromSwiftFormat** - Previously had only basic test, now thoroughly tested
5. **SwiftSnapshotError** - Previously untested, now has 10 tests covering all cases
6. **SnapshotRenderContext** - Previously untested, now has 12 comprehensive tests
7. **SnapshotRendererRegistry** - Previously had minimal testing, now has 9 comprehensive tests
8. **SwiftSnapshotConfig** - Previously only integration tested, now has 20 dedicated tests

## Other Improvements

- Added `.profraw` and `.profdata` to `.gitignore` to exclude code coverage files
- All new tests follow the existing test structure and conventions
- Tests are organized in logical suites within the `SnapshotTests` structure
- Thread safety tests added for concurrent components

## Test Execution

All 174 tests pass successfully:
```
✔ Test run with 174 tests in 17 suites passed after 1.2 seconds.
```

## Usage

Run tests with code coverage:
```bash
swift test --enable-code-coverage
```
