# SwiftSnapshot

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> [!WARNING]
> This is a work in progress everything is not ready yet some feature may be buggy or work in very limited use cases.

**Generate type-safe Swift source fixtures from runtime values.**

SwiftSnapshot converts in-memory objects into compilable Swift code that you can commit, diff, and reuse anywhere: no JSON, no decoding, just Swift.

```swift
let user = User(id: 42, name: "Alice", role: .admin)
try user.exportSnapshot(variableName: "testUser")

// Creates: User+testUser.swift
// extension User {
//     static let testUser: User = User(
//         id: 42,
//         name: "Alice",
//         role: .admin
//     )
// }
```

_This project was built using an LLM. It shows that, with proper guidance, they can create something quite effective_

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mackoj/swift-snapshot.git", from: "0.1.0")
]
```

Or in Xcode: **File → Add Packages** → Enter repository URL

### Requirements

- Swift 5.9+
- macOS (currently macOS-only)
- iOS 16+

---

## Features

### Core Capabilities

- **Type-Safe Generation** - Compiler-verified fixtures
- **Broad Type Support** - Primitives, collections, Foundation types, custom types
- **Custom Renderers** - Extensible type handling
- **Deterministic Output** - Sorted keys, stable ordering
- **Smart Formatting** - EditorConfig and swift-format integration
- **Thread-Safe** - Concurrent exports supported
- **DEBUG-Only** - Zero production overhead

### Supported Types

**Built-in:**
- Primitives: `String`, `Int`, `Double`, `Float`, `Bool`, `Character`
- Collections: `Array`, `Dictionary`, `Set`
- Foundation: `Date`, `UUID`, `URL`, `Data`, `Decimal`
- Optionals: Automatic `nil` handling

**Custom Types:**
- Structs and classes via reflection
- Enums with associated values
- Nested structures
- User-defined via custom renderers

### Macro Enhancements

Optional compile-time macros add:

- `@SwiftSnapshot` - Type-level fixture support
- `@SnapshotIgnore` - Exclude properties
- `@SnapshotRedact` - Mask sensitive values
- `@SnapshotRename` - Change property names

---

## Motivation

Traditional test fixtures have problems:

| Problem | SwiftSnapshot Solution |
|---------|----------------------|
| JSON fixtures break silently when types change | **Compiler-verified** - won't build if types change |
| Hardcoded test data scattered across files | **Centralized fixtures** with single source of truth |
| Binary snapshots have opaque diffs | **Human-readable diffs** in version control |
| Decoding overhead in every test | **Zero overhead** - use fixtures directly |
| No IDE support for fixture data | **Full autocomplete** and navigation |

### Learn More

- [What is SwiftSnapshot and Why?](Sources/SwiftSnapshotCore/Documentation.docc/Articles/WhatAndWhy.md) - Purpose and motivation
- [Architecture](Sources/SwiftSnapshotCore/Documentation.docc/Articles/Architecture.md) - Technical design
- [Basic Usage](Sources/SwiftSnapshotCore/Documentation.docc/Articles/BasicUsage.md) - Examples and patterns
- [Custom Renderers](Sources/SwiftSnapshotCore/Documentation.docc/Articles/CustomRenderers.md) - Type-specific rendering
- [Formatting Configuration](Sources/SwiftSnapshotCore/Documentation.docc/Articles/FormattingConfiguration.md) - Code style setup

---

## Usage

### Basic Export

```swift
let user = User(id: 42, name: "Alice", role: .admin)

try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser"
)

// Use fixture
let reference = User.testUser
```

### With Documentation

```swift
try SwiftSnapshotRuntime.export(
    instance: product,
    variableName: "sampleProduct",
    header: "// Test Fixtures",
    context: "Standard product fixture for pricing tests"
)
```

### Custom Output

```swift
try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser",
    outputBasePath: "/path/to/fixtures",
    fileName: "UserFixtures"
)
```

### With Macros

```swift
@SwiftSnapshot(folder: "Fixtures")
struct User {
    let id: String
    @SnapshotRename("displayName")
    let name: String
    @SnapshotRedact(mask: "***")
    let apiKey: String
    @SnapshotIgnore
    let cache: [String: Any]
}

try user.exportSnapshot(variableName: "testUser")
```

### Custom Renderers

```swift
SnapshotRendererRegistry.register(MyType.self) { value, context in
    ExprSyntax(stringLiteral: "MyType(value: \"\(value.property)\")")
}
```

### In Tests

```swift
class Tests: XCTestCase {
    func testFeature() {
        let state = captureState()
        try state.exportSnapshot(variableName: "testState")
        
        // Use in other tests
        XCTAssertEqual(State.testState.isValid, true)
    }
}
```

### In SwiftUI Previews

```swift
#Preview {
    UserView(user: .testUser)
}
```

### Example: The Refactoring Problem

```swift
// You rename a property
struct User {
-   let name: String
+   let fullName: String
}

// ❌ JSON fixtures: Silent runtime failure
{"name": "Alice"}  // Still has old property name

// ✅ Swift fixtures: Compile-time error
User(name: "Alice")  // Error: No parameter 'name'
                     // Compiler guides you to fix it
```

---

## Configuration

### Global Settings

```swift
SwiftSnapshotConfig.setGlobalRoot(URL(fileURLWithPath: "./Fixtures"))
SwiftSnapshotConfig.setGlobalHeader("// Test Fixtures")
```

### Formatting

```swift
// From .editorconfig
SwiftSnapshotConfig.setFormatConfigSource(
    .editorconfig(URL(fileURLWithPath: ".editorconfig"))
)

// Or manual
let profile = FormatProfile(
    indentStyle: .space,
    indentSize: 2,
    endOfLine: .lf,
    insertFinalNewline: true,
    trimTrailingWhitespace: true
)
SwiftSnapshotConfig.setFormattingProfile(profile)
```

### Dependency Injection

For isolated test configuration:

```swift
import Dependencies

withDependencies {
    $0.swiftSnapshotConfig = .init(
        getGlobalRoot: { URL(fileURLWithPath: "/tmp/fixtures") },
        // ... other overrides
    )
} operation: {
    // Tests with custom config
}
```

---

## DEBUG Only Architecture

SwiftSnapshot follows the same philosophy as [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) and [xctest-dynamic-overlay](https://github.com/pointfreeco/xctest-dynamic-overlay):

**Development tools should not affect production code.**

### How It Works

- **DEBUG builds**: Full functionality
- **RELEASE builds**: APIs become no-ops
- **Result**: Zero production overhead

```swift
// Safe to leave in codebase
let url = try user.exportSnapshot()
// DEBUG: Creates file
// RELEASE: Returns placeholder, no I/O
```

---

## Contributing

Contributions welcome! For major changes, please open an issue first.

## Acknowledgments

Built with:
- [SwiftSyntax](https://github.com/apple/swift-syntax) - Code generation
- [swift-format](https://github.com/swiftlang/swift-format) - Formatting
- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) - Dependency injection
- [swift-issue-reporting](https://github.com/pointfreeco/swift-issue-reporting) - Error messages

Inspired by [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)

## License

MIT - See [LICENSE](LICENSE) for details
