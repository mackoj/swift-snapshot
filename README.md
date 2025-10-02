# SwiftSnapshot 📋

**Generate type-safe, human‑readable Swift source fixtures directly from live runtime values.**

SwiftSnapshot turns your in‑memory objects into compilable Swift code you can commit, diff, and reuse anywhere—tests, previews, documentation, diagnostics—without bespoke serializers.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Installation

### Swift Package Manager

Add SwiftSnapshot to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mackoj/swift-snapshot.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftSnapshot"]
)
```

Or add it via Xcode: **File → Add Packages** and enter the repository URL.

---

## Quick Start

```swift
import SwiftSnapshot

struct User {
    let id: Int
    let name: String
}

let user = User(id: 42, name: "Alice")

// Generate and export Swift code
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser"
)

// Generated file contains:
// extension User {
//   static let testUser: User = User(id: 42, name: "Alice")
// }
```

---

## Key Idea

Instead of snapshotting opaque data blobs (JSON, plist, binary), SwiftSnapshot emits Swift declarations:

```swift
extension User {
  static let testUserCreation: User = User(
    id: 42,
    name: "Alice",
    role: .admin,
    isActive: true,
    tags: ["admin", "beta"]
  )
}
```

These fixtures:
- ✅ **Compile** (type safety)
- ✅ **Diff cleanly** (great review ergonomics)
- ✅ **Instantly reusable** (no decoding step)
- ✅ **Evolve with refactors** (compiler guides updates)

---

## Features

### ✅ Currently Implemented

- **Runtime API**: Generate Swift fixtures from any value at runtime
- **Primitive Types**: String, Int, Double, Float, Bool, Character
- **Foundation Types**: Date, UUID, URL, Data, Decimal
- **Collections**: Array, Dictionary, Set (with deterministic ordering)
- **Optional Values**: Automatic nil handling
- **Custom Types**: Structs, classes, and enums via reflection
- **Nested Structures**: Recursive rendering of complex types
- **Custom Renderers**: Extensible registry for custom type handling
- **Configuration**: Global settings for output paths, headers, formatting
- **Headers & Context**: Add documentation and custom headers to generated files
- **File Management**: Smart path resolution, overwrite protection
- **String Escaping**: Proper handling of special characters, unicode, and emoji
- **Thread-Safe**: Concurrent exports supported

### 🚧 Planned (Macro Layer)

The macro layer is planned for future development and will provide:

- **Type-Level Annotation**: `@SwiftSnapshot` for compile-time metadata
- **Property Attributes**: `@SnapshotIgnore`, `@SnapshotRename`, `@SnapshotRedact`
- **Optimized Generation**: Skip reflection for annotated types
- **Enhanced Enum Support**: Full associated value labels

---

## Usage Examples

### Basic Export

```swift
import SwiftSnapshot

enum Role {
    case admin
    case manager
    case employee
}

struct User {
    let id: Int
    var name: String
    var role: Role
    var isActive: Bool
    var tags: [String]
}

let user = User(
    id: 42, 
    name: "Alice", 
    role: .admin, 
    isActive: true, 
    tags: ["admin", "beta"]
)

let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUserCreation",
    testName: #function
)

print("Snapshot written to: \(url.path)")

// Use the generated fixture
let reference = User.testUserCreation
XCTAssertTrue(reference.isActive)
```

### With Headers and Context

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: product,
    variableName: "sampleProduct",
    header: """
    // Test Fixtures
    // Generated: \(Date())
    """,
    context: """
    Standard product fixture used across pricing tests.
    Represents a typical e-commerce product.
    """
)
```

Generated output:
```swift
// Test Fixtures
// Generated: 2024-01-15...

/// Standard product fixture used across pricing tests.
/// Represents a typical e-commerce product.
import Foundation

extension Product {
    static let sampleProduct: Product = Product(...)
}
```

### XCTest Integration

```swift
final class UserServiceTests: XCTestCase {
    func testUserCreation() throws {
        let user = User(
            id: 1, 
            name: "Test User", 
            email: "test@example.com"
        )
        
        // Export for use in other tests
        let url = try SwiftSnapshotRuntime.export(
            instance: user,
            variableName: "testUserCreation",
            testName: #function
        )
        
        // Use the fixture
        XCTAssertEqual(User.testUserCreation.id, 1)
        XCTAssertEqual(User.testUserCreation.name, "Test User")
    }
}
```

### Custom Output Directory

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser",
    outputBasePath: "/path/to/fixtures"
)
```

### Custom File Name

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "adminUser",
    fileName: "User+AdminFixtures"
)
// Creates: User+AdminFixtures.swift
```

---

## Supported Types

### Built-In Rendering

- **Primitives**: `String`, `Int`, `Double`, `Float`, `Bool`, `Character`
- **Foundation**: `Date`, `UUID`, `URL`, `Decimal`, `Data`
- **Collections**: `Array`, `Dictionary`, `Set`
- **Optionals**: `T?` (automatic nil handling)
- **Custom Types**: Any struct, class, or enum via reflection

### Example Output

```swift
// String escaping
"Hello\nWorld" → "Hello\\nWorld"

// Date
Date(timeIntervalSince1970: 1234567890.0)

// UUID
UUID(uuidString: "12345678-1234-1234-1234-123456789012")!

// URL
URL(string: "https://example.com")!

// Data (small)
Data([0x01, 0x02, 0x03])

// Data (large)
Data(base64Encoded: "...")!

// Dictionary (sorted keys)
["key1": "value1", "key2": "value2"]

// Set (deterministic order)
Set(["ios", "swift", "testing"])
```

---

## Configuration

### Global Settings

```swift
// Set global output directory
SwiftSnapshotConfig.setGlobalRoot(
    URL(fileURLWithPath: "/path/to/fixtures")
)

// Set global header for all exports
SwiftSnapshotConfig.setGlobalHeader("""
// Project Test Fixtures
// Auto-generated - Do not edit manually
""")

// Configure formatting
var profile = FormatProfile()
profile.indentSize = 2
SwiftSnapshotConfig.setFormattingProfile(profile)

// Configure rendering options
var options = RenderOptions()
options.sortDictionaryKeys = true
options.setDeterminism = true
SwiftSnapshotConfig.setRenderOptions(options)
```

### Directory Resolution Priority

1. `outputBasePath` parameter (highest priority)
2. `SwiftSnapshotConfig.setGlobalRoot()`
3. `SWIFT_SNAPSHOT_ROOT` environment variable

---

## Formatting Configuration

SwiftSnapshot supports configurable code formatting via `.editorconfig` or `.swift-format` files:

```swift
// Use .editorconfig
let configURL = URL(fileURLWithPath: ".editorconfig")
SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))

// Or use .swift-format
let formatURL = URL(fileURLWithPath: ".swift-format")
SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(formatURL))

// Load and apply configuration
if let source = SwiftSnapshotConfig.getFormatConfigSource() {
    let profile = try FormatConfigLoader.loadProfile(from: source)
    SwiftSnapshotConfig.setFormattingProfile(profile)
}
```

Supported `.editorconfig` properties:
- `indent_style` (space)
- `indent_size` (1-8)
- `end_of_line` (lf/crlf)
- `insert_final_newline` (true/false)
- `trim_trailing_whitespace` (true/false)

See [Documentation/FormattingConfiguration.md](Documentation/FormattingConfiguration.md) for details.

---

## Custom Renderers

Register custom renderers for your types:

```swift
struct CustomType {
    let value: String
}

// Register a custom renderer
SnapshotRendererRegistry.register(CustomType.self) { value, context in
    ExprSyntax(stringLiteral: "CustomType(value: \"CUSTOM_\(value.value)\")")
}

let custom = CustomType(value: "test")
let code = try SwiftSnapshotRuntime.generateSwiftCode(
    instance: custom, 
    variableName: "myCustom"
)
// Uses your custom renderer
```

See [Documentation/CustomRenderers.md](Documentation/CustomRenderers.md) for comprehensive guide.

---

## Performance

SwiftSnapshot is designed for high performance:

- **Large Arrays**: 10,000 elements render in ~0.2s
- **Complex Structures**: 1,000 nested models in <1s
- **Concurrent Exports**: 50 parallel exports supported
- **Thread-Safe**: All APIs are thread-safe
- **Deterministic**: Consistent output under concurrent load

Performance characteristics from test suite:
```
Large array (10k Int):        0.225s
Complex structures (1k):      <1.0s  
Dictionary (1k entries):      0.099s
Concurrent exports (50):      0.019s
```

---

## API Reference

### SwiftSnapshotRuntime

```swift
public enum SwiftSnapshotRuntime {
    /// Export a value as a Swift source file
    @discardableResult
    public static func export<T>(
        instance: T,
        variableName: String,
        fileName: String? = nil,
        outputBasePath: String? = nil,
        allowOverwrite: Bool = true,
        header: String? = nil,
        context: String? = nil,
        testName: String? = nil,
        line: UInt = #line,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath
    ) throws -> URL

    /// Generate Swift code without writing to disk
    public static func generateSwiftCode<T>(
        instance: T,
        variableName: String,
        header: String? = nil,
        context: String? = nil
    ) throws -> String
}
```

**Parameters:**
- `variableName`: Identifier for the generated static property
- `fileName`: Optional custom file name (`.swift` added automatically)
- `outputBasePath`: Override output directory for this export
- `allowOverwrite`: Whether to replace existing files (default: `true`)
- `header`: Custom header text (overrides global header)
- `context`: Documentation comment for the generated property
- `testName`: Optional test name for grouping (uses `#function`)
- `fileID`/`filePath`/`line`: Source location for directory inference

**Returns:** URL to the created `.swift` file

### SwiftSnapshotConfig

```swift
public enum SwiftSnapshotConfig {
    public static func setGlobalRoot(_ url: URL?)
    public static func getGlobalRoot() -> URL?
    public static func setGlobalHeader(_ header: String?)
    public static func getGlobalHeader() -> String?
    public static func setFormattingProfile(_ profile: FormatProfile)
    public static func formattingProfile() -> FormatProfile
    public static func setRenderOptions(_ options: RenderOptions)
    public static func renderOptions() -> RenderOptions
}
```

---

## Why SwiftSnapshot?

### 🔍 Human‑Readable
Fixtures are plain Swift—review, search, and reason about them like any other code.

### 📝 Diff Friendly
Line‑level semantic diffs. No sprawling JSON updates or binary churn.

### ♻️ Multi‑Context Reuse
Use in previews, tests, scripts, debugging hooks, documentation samples—no decoding layer.

### 🛡️ Type Safe
Refactors surface compiler errors instead of silent runtime mismatches.

### 📦 Lightweight Storage
No git‑lfs or compression; just fast, lean Swift source.

### 🗂️ Scalable Organization
Deterministic directory strategy with multiple override layers.

---

## Comparison to Alternatives

| Feature | SwiftSnapshot | JSON Fixtures | Snapshot Testing |
|---------|---------------|---------------|------------------|
| Human Readable | ✅ Swift source | ❌ JSON structure | ❌ Binary/text blobs |
| Type Safety | ✅ Compile-time | ❌ Runtime parsing | ❌ No type info |
| Version Control | ✅ Meaningful diffs | ⚠️ Hard to review | ❌ Opaque changes |
| Reusability | ✅ Use anywhere | ⚠️ Parsing required | ❌ Test-only |
| IDE Support | ✅ Full autocomplete | ❌ No assistance | ❌ No assistance |
| Debugging | ✅ Easy inspection | ⚠️ Mental parsing | ❌ External tools |

---

## Examples

See [Examples/BasicUsage.md](Examples/BasicUsage.md) for comprehensive usage examples including:
- Primitive and collection types
- Nested structures
- Custom renderers
- Testing integration
- Configuration options

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

---

## Acknowledgments

- Inspired by snapshot testing ecosystems (e.g., [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing))
- Built with [SwiftSyntax](https://github.com/apple/swift-syntax) for robust code generation
- Uses [swift-issue-reporting](https://github.com/pointfreeco/swift-issue-reporting) for better error messages

---

## License

MIT License. See [LICENSE](LICENSE) for details.
