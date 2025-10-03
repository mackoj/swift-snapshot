# Architecture Overview

Understanding SwiftSnapshot's design, components, and implementation.

## Overview

SwiftSnapshot is built on a layered architecture that separates concerns and provides clear extension points. The library follows Swift best practices and integrates with industry-standard tools.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Application                          │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────────────┐
│              SwiftSnapshot Public API                        │
│  - SwiftSnapshotRuntime.export()                            │
│  - Macro-generated convenience methods                       │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────────────┐
│                   Core Components                            │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ValueRenderer │  │CodeFormatter │  │PathResolver  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
│  ┌──────┴────────┐  ┌──────┴──────┐   ┌──────┴──────┐     │
│  │RendererRegistry│  │FormatLoader│   │Config System│     │
│  └───────────────┘  └─────────────┘   └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────────────┐
│              External Dependencies                           │
│  - SwiftSyntax (AST generation)                             │
│  - swift-format (code formatting)                            │
│  - swift-dependencies (DI)                                   │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### Runtime API Layer

The ``SwiftSnapshotRuntime`` enum provides the main entry point:

- **export()**: Converts values to files
- **generateSwiftCode()**: Internal code generation
- **sanitizeVariableName()**: Ensures valid Swift identifiers

### Value Rendering System

``ValueRenderer`` converts Swift values to SwiftSyntax expressions:

1. **Custom Renderer Check**: Queries ``SnapshotRendererRegistry``
2. **Built-in Renderers**: Handles primitives, collections, Foundation types
3. **Reflection Fallback**: Uses Mirror for custom types

**Supported Types:**
- Primitives: String, Int, Double, Float, Bool, Character
- Collections: Array, Dictionary, Set
- Foundation: Date, UUID, URL, Data, Decimal
- Custom: Any struct/class/enum via reflection or custom renderers

### Code Formatting Pipeline

``CodeFormatter`` handles the complete formatting process:

1. **Syntax Tree Construction**: Builds SourceFileSyntax with all components
2. **swift-format Integration**: Applies formatting rules
3. **Post-Processing**: Handles EditorConfig properties

### Configuration System

``SwiftSnapshotConfig`` provides thread-safe global configuration:

- **Directory Resolution**: Multiple priority levels
- **Format Profiles**: Indentation, line endings, whitespace
- **Render Options**: Determinism, sorting, thresholds
- **Format Sources**: .editorconfig or .swift-format support

### Custom Renderer Registry

``SnapshotRendererRegistry`` enables type-specific rendering:

- Thread-safe registration
- Type-based lookup
- Checked before built-in renderers

## Data Flow

### Export Operation

```
1. User calls SwiftSnapshotRuntime.export()
   ↓
2. Sanitize variable name
   ↓
3. Generate Swift code via generateSwiftCode()
   ├─→ Load configuration (format + render options)
   ├─→ Create SnapshotRenderContext
   ├─→ Render value with ValueRenderer
   │   ├─→ Check custom renderers
   │   ├─→ Try built-in renderers
   │   └─→ Fall back to reflection
   └─→ Format code with CodeFormatter
       ├─→ Build SwiftSyntax tree
       ├─→ Apply swift-format
       └─→ Post-process (line endings, whitespace)
   ↓
4. Resolve output path via PathResolver
   ├─→ Check outputBasePath parameter
   ├─→ Check global configuration
   ├─→ Check environment variable
   └─→ Use default location
   ↓
5. Write file to disk
   ↓
6. Return file URL
```

### Rendering Process

```
ValueRenderer.render(value, context)
   ↓
1. Check SnapshotRendererRegistry for custom renderer
   ├─→ Found: Use custom logic
   └─→ Not found: Continue
   ↓
2. Check if primitive type
   ├─→ String: Escape and quote
   ├─→ Number: Direct literal
   ├─→ Bool: true/false
   └─→ Not primitive: Continue
   ↓
3. Check if Optional
   ├─→ nil: Return "nil"
   └─→ Wrapped: Unwrap and recurse
   ↓
4. Check if Collection
   ├─→ Array: Render elements
   ├─→ Dictionary: Sort keys, render pairs
   ├─→ Set: Deterministic order, render elements
   └─→ Not collection: Continue
   ↓
5. Check if Foundation type
   ├─→ Date: timeIntervalSince1970
   ├─→ UUID: uuidString
   ├─→ URL: string representation
   ├─→ Data: Hex or base64
   └─→ Not Foundation: Continue
   ↓
6. Use reflection (Mirror)
   ├─→ Struct/Class: Render properties
   ├─→ Enum: Render case + associated values
   └─→ Unknown: Throw unsupportedType error
```

## Configuration Precedence

### Output Directory

Priority (highest to lowest):
1. `outputBasePath` parameter in export()
2. `SwiftSnapshotConfig.setGlobalRoot()`
3. `SWIFT_SNAPSHOT_ROOT` environment variable
4. Default: `__Snapshots__` adjacent to calling file

### Formatting

Priority (highest to lowest):
1. `header` parameter in export() (overrides global header)
2. Global header via `SwiftSnapshotConfig.setGlobalHeader()`
3. Format config source (.editorconfig or .swift-format)
4. Manually set `FormatProfile`
5. Library defaults

## Thread Safety

All public APIs are thread-safe:

- **Configuration**: Protected by `NSLock`
- **Registry**: Protected by `NSLock`
- **File I/O**: Atomic writes
- **Concurrent Exports**: Fully supported

## DEBUG-Only Architecture

All public APIs are wrapped in `#if DEBUG`:

```swift
#if DEBUG
// Full implementation
#else
// No-op or placeholder
#endif
```

**Benefits:**
- Zero runtime overhead in release builds
- Zero binary bloat (entire library excluded)
- No accidental snapshot generation in production

## Error Handling

``SwiftSnapshotError`` provides detailed error information:

- **unsupportedType**: Type cannot be rendered (with path)
- **io**: File system operation failed
- **overwriteDisallowed**: File exists and protection enabled
- **formatting**: Code formatting failed
- **reflection**: Runtime type inspection failed

All errors include context for debugging.

## Extension Points

### Custom Renderers

Register type-specific rendering logic:

```swift
SnapshotRendererRegistry.register(MyType.self) { value, context in
    // Custom rendering logic
    return ExprSyntax(...)
}
```

### Format Configuration

Integrate with project formatting:

```swift
SwiftSnapshotConfig.setFormatConfigSource(
    .editorconfig(URL(fileURLWithPath: ".editorconfig"))
)
```

### Dependency Injection

Override configuration in tests:

```swift
withDependencies {
    $0.swiftSnapshotConfig = .init(
        getGlobalRoot: { customRoot },
        // ... other overrides
    )
} operation: {
    // Tests with isolated config
}
```

## Performance Characteristics

From test suite benchmarks:

- **Large Array (10k Int)**: ~0.2s
- **Complex Structures (1k)**: <1s
- **Dictionary (1k entries)**: ~0.1s
- **Concurrent Exports (50)**: ~0.02s

All operations are optimized for:
- Minimal allocations
- Efficient string building
- Deterministic output
- Thread-safe concurrent access

## See Also

- ``SwiftSnapshotRuntime`` - Main API
- ``ValueRenderer`` - Rendering engine
- ``CodeFormatter`` - Formatting pipeline
- ``SwiftSnapshotConfig`` - Configuration
- ``SnapshotRendererRegistry`` - Custom renderers
