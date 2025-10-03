# SwiftSnapshot

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Generate type-safe Swift source fixtures from runtime values.**

SwiftSnapshot converts in-memory objects into compilable Swift code that you can commit, diff, and reuse anywhere—no JSON, no decoding, just Swift.

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

---

> **⚠️ DEBUG-Only Design**: SwiftSnapshot is a development tool with **zero production impact**. All APIs are disabled in release builds—no runtime overhead, no binary bloat.

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

## 🔒 DEBUG-Only Architecture

SwiftSnapshot follows the same philosophy as libraries like [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) and [xctest-dynamic-overlay](https://github.com/pointfreeco/xctest-dynamic-overlay): **test infrastructure should not impact production code**.

### How It Works

All public APIs are wrapped in `#if DEBUG` compiler directives:

- **In DEBUG builds**: Full functionality - snapshot generation, file I/O, configuration
- **In RELEASE builds**: All methods become no-ops or return placeholder values
- **Result**: Zero runtime overhead, zero binary bloat in production

### Example

```swift
// This code is safe to leave in your codebase
@SwiftSnapshot
struct User {
    let id: Int
    let name: String
}

// In DEBUG: Creates snapshot file
// In RELEASE: Returns placeholder URL, no I/O
let url = try user.exportSnapshot()
```

### Best Practices

While the library is DEBUG-only, you can still wrap your snapshot code in `#if DEBUG` for clarity:

```swift
#if DEBUG
let url = try user.exportSnapshot(variableName: "testUser")
print("Snapshot saved to: \(url.path)")
#endif
```

This makes your intent explicit and prevents accidentally relying on the snapshot URL in production code paths.

---

## Quick Start

### Basic Usage

```swift
import SwiftSnapshot

let user = User(id: 42, name: "Alice", role: .admin)

// Generate fixture
try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser"
)

// Use in tests, previews, etc.
let reference = User.testUser
```

### With Macros

Add enhanced control with compile-time macros:

```swift
@SwiftSnapshot
struct User {
    let id: Int
    let name: String
    
    @SnapshotIgnore
    let cache: [String: Any]
}

// Macro adds convenience method
try user.exportSnapshot(variableName: "testUser")
```

### Output

Both approaches generate clean Swift code:

```swift
// File: User+testUser.swift
import Foundation

extension User {
    static let testUser: User = User(
        id: 42,
        name: "Alice",
        role: .admin
    )
}
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
- **Compile** (type safety)
- **Diff cleanly** (great review ergonomics)
- **Instantly reusable** (no decoding step)
- **Evolve with refactors** (compiler guides updates)

---

## Features

### Currently Implemented

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

### Macro Layer

The macro layer provides compile-time code generation for enhanced control:

- **Type-Level Annotation**: `@SwiftSnapshot` for compile-time metadata generation
- **Property Attributes**: `@SnapshotIgnore`, `@SnapshotRename`, `@SnapshotRedact`
- **Optimized Generation**: Skip reflection for macro-annotated types
- **Enhanced Enum Support**: Full associated value labels with compile-time generation
- **Redaction Modes**: Mask or hash sensitive properties
- **Folder Organization**: Specify output directories per type

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
@SwiftSnapshot(folder: "Fixtures/Users")
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
    @SnapshotIgnore
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

**Generated Members:**
- `static let __swiftSnapshot_folder: String?` - Stores folder parameter
- `static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata]` - Property metadata array
- `static func __swiftSnapshot_makeExpr(from:) -> String` - Expression builder
- `func exportSnapshot(...)` - Convenience export method

**Example:**
```swift
@SwiftSnapshot(folder: "Fixtures/Products")
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

**Examples:**
```swift
@SwiftSnapshot
struct SecureData {
    @SnapshotRedact(mask: "SECRET")
    let apiKey: String  // Generated as: apiKey: "SECRET"
    
    @SnapshotRedact(hash: true)
    let password: String  // Generated as: password: "<hashed>"
}
```

**Note:** To completely omit a property from the snapshot, use `@SnapshotIgnore` instead.

**Diagnostics:**
- Error if multiple redaction modes specified

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

> **Note**: All configuration APIs are DEBUG-only. They have no effect in release builds.

### Global Settings (Static API)

```swift
#if DEBUG
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
let profile = FormatProfile(
    indentStyle: .space,
    indentSize: 2,
    endOfLine: .lf,
    insertFinalNewline: true,
    trimTrailingWhitespace: true
)
SwiftSnapshotConfig.setFormattingProfile(profile)

// Configure rendering options
let options = RenderOptions(
    sortDictionaryKeys: true,
    setDeterminism: true,
    dataInlineThreshold: 16,
    forceEnumDotSyntax: true
)
SwiftSnapshotConfig.setRenderOptions(options)

// Reset to library defaults
SwiftSnapshotConfig.resetToLibraryDefaults()
#endif
```

### Dependency Injection (Recommended for Tests)

SwiftSnapshot integrates with [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) for testable configuration:

```swift
import Dependencies
import SwiftSnapshot

// In your tests, override configuration using dependency injection
withDependencies {
  $0.swiftSnapshotConfig = .init(
    getGlobalRoot: { URL(fileURLWithPath: "/tmp/test-fixtures") },
    setGlobalRoot: { _ in },
    getGlobalHeader: { "// Test Fixtures" },
    setGlobalHeader: { _ in },
    getFormatConfigSource: { nil },
    setFormatConfigSource: { _ in },
    getRenderOptions: { 
      RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: true,
        dataInlineThreshold: 8,
        forceEnumDotSyntax: true
      )
    },
    setRenderOptions: { _ in },
    getFormatProfile: {
      FormatProfile(
        indentStyle: .space,
        indentSize: 2,
        endOfLine: .lf,
        insertFinalNewline: false,
        trimTrailingWhitespace: true
      )
    },
    setFormatProfile: { _ in },
    resetToLibraryDefaults: { },
    libraryDefaultRenderOptions: { SwiftSnapshotConfig.libraryDefaultRenderOptions() },
    libraryDefaultFormatProfile: { SwiftSnapshotConfig.libraryDefaultFormatProfile() }
  )
} operation: {
  // Your test code here - all SwiftSnapshot calls will use the overridden config
  let code = try SwiftSnapshotRuntime.generateSwiftCode(
    instance: myTestData,
    variableName: "fixture"
  )
}

// Or use the dependency directly in your code
@Dependency(\.swiftSnapshotConfig) var snapshotConfig
let options = snapshotConfig.getRenderOptions()
```

**Benefits of Dependency Injection:**
- ✅ Isolated test configuration without global state pollution
- ✅ Parallel test execution safety
- ✅ Easy to mock and stub configuration values
- ✅ Type-safe configuration access
- ✅ Compatible with existing static API during migration

### Directory Resolution Priority

1. `outputBasePath` parameter (highest priority)
2. `SwiftSnapshotConfig.setGlobalRoot()` or `swiftSnapshotConfig.getGlobalRoot()`
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

> **Note**: Custom renderer registration is DEBUG-only.

Register custom renderers for your types:

```swift
struct CustomType {
    let value: String
}

#if DEBUG
// Register a custom renderer (DEBUG only)
SnapshotRendererRegistry.register(CustomType.self) { value, context in
    ExprSyntax(stringLiteral: "CustomType(value: \"CUSTOM_\(value.value)\")")
}
#endif

let custom = CustomType(value: "test")

#if DEBUG
let url = try SwiftSnapshotRuntime.export(
    instance: custom, 
    variableName: "myCustom"
)
// Uses your custom renderer and exports to file
#endif
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

> **Important**: All public APIs are DEBUG-only. In release builds, they become no-ops or return placeholder values.

### SwiftSnapshotRuntime

```swift
public enum SwiftSnapshotRuntime {
    /// Export a value as a Swift source file
    /// **Debug Only**: No-op in release builds, returns placeholder URL
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
    public static func setFormatConfigSource(_ source: FormatConfigSource?)
    public static func getFormatConfigSource() -> FormatConfigSource?
    public static func resetToLibraryDefaults()
    public static func libraryDefaultRenderOptions() -> RenderOptions
    public static func libraryDefaultFormatProfile() -> FormatProfile
}
```

### SwiftSnapshotConfigClient (Dependency Injection)

```swift
public struct SwiftSnapshotConfigClient: Sendable {
    public var getGlobalRoot: @Sendable () -> URL?
    public var setGlobalRoot: @Sendable (URL?) -> Void
    public var getGlobalHeader: @Sendable () -> String?
    public var setGlobalHeader: @Sendable (String?) -> Void
    public var getFormatConfigSource: @Sendable () -> FormatConfigSource?
    public var setFormatConfigSource: @Sendable (FormatConfigSource?) -> Void
    public var getRenderOptions: @Sendable () -> RenderOptions
    public var setRenderOptions: @Sendable (RenderOptions) -> Void
    public var getFormatProfile: @Sendable () -> FormatProfile
    public var setFormatProfile: @Sendable (FormatProfile) -> Void
    public var resetToLibraryDefaults: @Sendable () -> Void
    public var libraryDefaultRenderOptions: @Sendable () -> RenderOptions
    public var libraryDefaultFormatProfile: @Sendable () -> FormatProfile
    
    // Convenience methods
    public func makeRenderOptions() -> RenderOptions
    public func makeFormatProfile() -> FormatProfile
    
    // Live implementation
    public static let live: SwiftSnapshotConfigClient
}

// Access via swift-dependencies
extension DependencyValues {
    public var swiftSnapshotConfig: SwiftSnapshotConfigClient { get set }
}
```

**Usage:**
```swift
import Dependencies

@Dependency(\.swiftSnapshotConfig) var config
let renderOpts = config.getRenderOptions()
```

---

## FAQ

### Why is SwiftSnapshot DEBUG-only?

SwiftSnapshot is a **development tool**, not a runtime feature. Similar to [xctest-dynamic-overlay](https://github.com/pointfreeco/xctest-dynamic-overlay) and test infrastructure in [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), it should have zero impact on your production binaries.

**Benefits:**
- ✅ Zero runtime overhead in production
- ✅ Zero binary bloat (entire library excluded from release builds)
- ✅ No accidental snapshot generation in production
- ✅ Safe to leave snapshot code in your codebase

### What happens in release builds?

All public methods become no-ops:
- `SwiftSnapshotRuntime.export()` returns a placeholder URL without I/O
- `exportSnapshot()` returns a placeholder URL without I/O
- Configuration setters do nothing
- Registry operations do nothing

### Can I conditionally use snapshots?

Yes! Wrap your snapshot code in `#if DEBUG` for clarity:

```swift
#if DEBUG
let url = try user.exportSnapshot()
print("Snapshot saved to: \(url.path)")
#endif
```

### Is this production-ready?

Yes! The DEBUG-only design means:
- Your production code is unaffected
- No performance impact
- No binary size increase
- Full functionality in DEBUG builds for development and testing

---

## Examples

See [Documentation/BasicUsage.md](Documentation/BasicUsage.md) for comprehensive usage examples including:
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
