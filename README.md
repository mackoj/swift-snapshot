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

// Using macros (recommended)
@SwiftSnapshot
struct User {
    let id: Int
    let name: String
}

let user = User(id: 42, name: "Alice")
let url = try user.exportSnapshot(variableName: "testUser")

// OR using runtime API directly
let urlDirect = try SwiftSnapshotRuntime.export(
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

### ✅ Macro Layer (New!)

The macro layer provides compile-time code generation for enhanced control:

- **Type-Level Annotation**: `@SwiftSnapshot` for compile-time metadata generation
- **Property Attributes**: `@SnapshotIgnore`, `@SnapshotRename`, `@SnapshotRedact`
- **Optimized Generation**: Skip reflection for macro-annotated types
- **Enhanced Enum Support**: Full associated value labels with compile-time generation
- **Redaction Modes**: Mask, hash, or remove sensitive properties
- **Folder Organization**: Specify output directories per type
- **Context Documentation**: Add documentation comments to generated code

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

### Using Macros for Enhanced Control

```swift
import SwiftSnapshot

// Basic macro usage
@SwiftSnapshot
struct Product {
    let id: String
    let name: String
    let price: Double
}

// Macro with property attributes
@SwiftSnapshot(folder: "Fixtures/Users", context: "Standard user fixture")
struct User {
    let id: String
    
    @SnapshotRename("displayName")
    let name: String
    
    @SnapshotRedact(mask: "***")
    let apiKey: String
    
    @SnapshotIgnore
    let transientCache: [String: Any]
}

// Export using macro-generated method
let user = User(id: "123", name: "Alice", apiKey: "secret", cache: [:])
let url = try user.exportSnapshot(variableName: "testUser")

// Enum with associated values
@SwiftSnapshot
enum Result {
    case success(value: Int)
    case failure(error: String)
}

let result = Result.success(value: 42)
let resultUrl = try result.exportSnapshot()
```

### Redaction Modes

```swift
@SwiftSnapshot
struct SecureData {
    let id: String
    
    // Mask with custom string
    @SnapshotRedact(mask: "REDACTED")
    let apiKey: String
    
    // Generate hash placeholder
    @SnapshotRedact(hash: true)
    let password: String
    
    // Remove from output entirely
    @SnapshotRedact(remove: true)
    let sessionToken: String
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

## Macro Reference

### @SwiftSnapshot

Marks a type for snapshot fixture export with compile-time code generation.

**Parameters:**
- `folder: String?` - Optional output directory hint (e.g., `"Fixtures/Users"`)
- `context: String?` - Optional documentation context added as comments

**Generated Members:**
- `static let __swiftSnapshot_folder: String?` - Stores folder parameter
- `static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata]` - Property metadata array
- `static func __swiftSnapshot_makeExpr(from:) -> String` - Expression builder
- `func exportSnapshot(...)` - Convenience export method

**Example:**
```swift
@SwiftSnapshot(folder: "Fixtures/Products", context: "Standard product fixture")
struct Product {
    let id: String
    let name: String
}
```

### @SnapshotIgnore

Excludes a property from snapshot generation. The property will not appear in the generated initializer or metadata.

**Example:**
```swift
@SwiftSnapshot
struct User {
    let id: String
    @SnapshotIgnore
    let transientCache: [String: Any]  // Excluded from snapshot
}
```

### @SnapshotRename

Renames a property in the generated initializer expression.

**Parameters:**
- Unlabeled `String` - The new name to use

**Example:**
```swift
@SwiftSnapshot
struct User {
    @SnapshotRename("displayName")
    let name: String  // Generated as displayName in snapshot
}
```

### @SnapshotRedact

Redacts sensitive property values in generated snapshots. Three modes available (mutually exclusive):

**Parameters:**
- `mask: String?` - Replace value with literal string (default: `"•••"`)
- `hash: Bool` - Replace with deterministic hash placeholder
- `remove: Bool` - Omit property from initializer entirely

**Examples:**
```swift
@SwiftSnapshot
struct SecureData {
    @SnapshotRedact(mask: "SECRET")
    let apiKey: String  // Generated as: apiKey: "SECRET"
    
    @SnapshotRedact(hash: true)
    let password: String  // Generated as: password: "<hashed>"
    
    @SnapshotRedact(remove: true)
    let sessionToken: String  // Omitted from output
}
```

**Diagnostics:**
- Error if multiple redaction modes specified
- Error if `remove` mode would create invalid initializer

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
