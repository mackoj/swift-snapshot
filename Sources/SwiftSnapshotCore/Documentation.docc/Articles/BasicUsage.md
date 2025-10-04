# Basic Usage Examples

Learn how to use SwiftSnapshot to generate type-safe Swift fixtures from runtime values.

## Simple Types

### Primitives

```swift
import SwiftSnapshot

// Integer
let count = 42
try SwiftSnapshotRuntime.export(instance: count, variableName: "testCount")
// Generates: extension Int { static let testCount: Int = 42 }

// String
let message = "Hello, World!"
try SwiftSnapshotRuntime.export(instance: message, variableName: "greeting")
// Generates: extension String { static let greeting: String = "Hello, World!" }

// Boolean
let isEnabled = true
try SwiftSnapshotRuntime.export(instance: isEnabled, variableName: "featureFlag")
// Generates: extension Bool { static let featureFlag: Bool = true }
```

### Foundation Types

```swift
import Foundation
import SwiftSnapshot

// Date
let timestamp = Date(timeIntervalSince1970: 1234567890)
try SwiftSnapshotRuntime.export(instance: timestamp, variableName: "launchDate")
// Generates: extension Date { static let launchDate: Date = Date(timeIntervalSince1970: 1234567890.0) }

// UUID
let identifier = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
try SwiftSnapshotRuntime.export(instance: identifier, variableName: "sessionId")
// Generates: extension UUID { static let sessionId: UUID = UUID(uuidString: "12345678-1234-1234-1234-123456789012")! }

// URL
let endpoint = URL(string: "https://api.example.com/v1/users")!
try SwiftSnapshotRuntime.export(instance: endpoint, variableName: "apiEndpoint")
// Generates: extension URL { static let apiEndpoint: URL = URL(string: "https://api.example.com/v1/users")! }
```

## Collections

### Arrays

```swift
let numbers = [1, 2, 3, 4, 5]
try SwiftSnapshotRuntime.export(instance: numbers, variableName: "fibonacci")
// Generates: extension Array { static let fibonacci: Array<Int> = [1,2,3,4,5] }

let names = ["Alice", "Bob", "Charlie"]
try SwiftSnapshotRuntime.export(instance: names, variableName: "teamMembers")
```

### Dictionaries

```swift
let config = ["timeout": "30", "retry": "3", "cache": "enabled"]
try SwiftSnapshotRuntime.export(instance: config, variableName: "defaultConfig")
// Generates: extension Dictionary { 
//   static let defaultConfig: Dictionary<String, String> = 
//     ["cache":"enabled","retry":"3","timeout":"30"]
// }
```

### Sets

```swift
let tags: Set<String> = ["swift", "ios", "testing"]
try SwiftSnapshotRuntime.export(instance: tags, variableName: "supportedTags")
// Generates: extension Set { static let supportedTags: Set<String> = Set(["ios","swift","testing"]) }
```

## Custom Types

### Structs

```swift
struct User {
    let id: Int
    let name: String
    let email: String
    let isActive: Bool
}

let user = User(id: 42, name: "Alice", email: "alice@example.com", isActive: true)
try SwiftSnapshotRuntime.export(instance: user, variableName: "testUser")
// Generates:
// extension User {
//   static let testUser: User = User(id: 42, name: "Alice", email: "alice@example.com", isActive: true)
// }
```

### Enums

```swift
enum Status {
    case active
    case pending
    case archived
}

let currentStatus = Status.active
try SwiftSnapshotRuntime.export(instance: currentStatus, variableName: "userStatus")
// Generates: extension Status { static let userStatus: Status = .active }
```

### Nested Structures

```swift
struct Address {
    let street: String
    let city: String
    let zip: String
}

struct Person {
    let name: String
    let age: Int
    let address: Address
}

let person = Person(
    name: "Bob",
    age: 35,
    address: Address(street: "123 Main St", city: "Springfield", zip: "12345")
)

try SwiftSnapshotRuntime.export(instance: person, variableName: "testPerson")
// Generates:
// extension Person {
//   static let testPerson: Person = Person(
//     name: "Bob", 
//     age: 35, 
//     address: Address(street: "123 Main St", city: "Springfield", zip: "12345")
//   )
// }
```

## Advanced Features

### Adding Headers

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser",
    header: """
    // Test Fixtures
    // Generated: \(Date())
    // DO NOT EDIT
    """
)
```

### Adding Documentation Context

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: product,
    variableName: "sampleProduct",
    context: """
    Standard product fixture used across pricing tests.
    Represents a typical e-commerce product with complete metadata.
    """
)
// Generates file with:
// import Foundation
// 
// extension Product { 
//     /// Standard product fixture used across pricing tests.
//     /// Represents a typical e-commerce product with complete metadata.
//     static let sampleProduct: Product = ...
// }
```

### Custom Output Directory

```swift
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser",
    outputBasePath: "/path/to/fixtures"
)
print("Exported to: \(url.path)")
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

## Configuration

### Global Settings

Configure SwiftSnapshot behavior globally using ``SwiftSnapshotConfig``:

```swift
// Set global output directory
SwiftSnapshotConfig.setGlobalRoot(URL(fileURLWithPath: "/path/to/fixtures"))

// Set global header for all exports
SwiftSnapshotConfig.setGlobalHeader("""
// Project Test Fixtures
// Auto-generated - Do not edit manually
""")

// Configure formatting with FormatProfile
let profile = FormatProfile(
    indentStyle: .space,
    indentSize: 2,
    endOfLine: .lf,
    insertFinalNewline: true,
    trimTrailingWhitespace: true
)
SwiftSnapshotConfig.setFormattingProfile(profile)

// Configure rendering options with RenderOptions
let options = RenderOptions(
    sortDictionaryKeys: true,
    setDeterminism: true,
    dataInlineThreshold: 16,
    forceEnumDotSyntax: true
)
SwiftSnapshotConfig.setRenderOptions(options)
```

See ``SwiftSnapshotConfig``, ``FormatProfile``, and ``RenderOptions`` for more details.

## Testing Integration

### XCTest Example

```swift
import XCTest
import SwiftSnapshot

class UserTests: XCTestCase {
    func testUserCreation() throws {
        let user = User(id: 1, name: "Test User", email: "test@example.com", isActive: true)
        
        // Export for use in other tests
        let url = try SwiftSnapshotRuntime.export(
            instance: user,
            variableName: "testUserCreation",
            testName: #function
        )
        
        // Now use the fixture
        XCTAssertEqual(User.testUserCreation.id, 1)
        XCTAssertTrue(User.testUserCreation.isActive)
    }
}
```

## Custom Renderers

For types that need custom rendering logic, use ``SnapshotRendererRegistry``:

```swift
struct CustomType {
    let value: String
}

// Register a custom renderer
SnapshotRendererRegistry.register(CustomType.self) { value, context in
    ExprSyntax(stringLiteral: "CustomType(value: \"CUSTOM_\(value.value)\")")
}

let custom = CustomType(value: "test")
let url = try SwiftSnapshotRuntime.export(instance: custom, variableName: "myCustom")
// Uses your custom renderer and exports to file
```

### Handling Transformed Initialization Values

Some types transform their input during initialization, making the original value inaccessible. For these types, create an alternative initializer and use a custom renderer:

```swift
@SwiftSnapshot
struct HashedValue {
    let hash: Int
    
    // Primary initializer - original string is lost
    init(from string: String) {
        self.hash = string.hash
    }
    
    // Alternative initializer for snapshots
    init(restoringHash hash: Int) {
        self.hash = hash
    }
}

// Register custom renderer
SnapshotRendererRegistry.register(HashedValue.self) { value, context in
    ExprSyntax(stringLiteral: "HashedValue(restoringHash: \(value.hash))")
}

let hashed = HashedValue(from: "secret")
let url = try hashed.exportSnapshot(variableName: "myHashed")
// Generates: HashedValue(restoringHash: 1234567890)
```

See <doc:CustomRenderers> for a comprehensive guide on custom type rendering.

## Tips and Best Practices

1. **Use in Tests**: Export fixtures during test runs to capture known-good states
2. **Version Control**: Commit generated fixtures to track changes over time
3. **Documentation**: Use the `context` parameter to document what each fixture represents
4. **Naming**: Use descriptive variable names that indicate the fixture's purpose
5. **Organization**: Use `fileName` parameter to group related fixtures
6. **Review Changes**: Diff generated fixtures during code review to catch unintended changes
