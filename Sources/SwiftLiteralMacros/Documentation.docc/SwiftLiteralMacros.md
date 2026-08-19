# ``SwiftLiteralMacros``

Compile-time code generation for enhanced snapshot control and optimized rendering.

## Overview

SwiftLiteralMacros provides Swift macros that enhance SwiftLiteral with compile-time features like property filtering, redaction, renaming, and optimized code generation. The macros eliminate the need for runtime reflection in many cases, producing more efficient and predictable snapshots.

### Available Macros

#### @SwiftLiteral

The main type-level macro that enables snapshot functionality:

```swift
@SwiftLiteral
struct User {
    let id: Int
    let name: String
}

let user = User(id: 1, name: "Alice")
try user.writeLiteral(variableName: "testUser")
```

**Features:**
- Generates an `writeLiteral()` convenience method
- Produces metadata for property introspection
- Enables property-level attributes
- Supports folder organization hints

#### @LiteralIgnore

Excludes properties from snapshot generation:

```swift
@SwiftLiteral
struct User {
    let id: String
    let name: String
    @LiteralIgnore
    let transientCache: [String: Any]
}
```

#### @LiteralRedact

Redacts sensitive values with masks or hashes:

```swift
@SwiftLiteral
struct SecureData {
    @LiteralRedact(.mask("***"))
    let apiKey: String
    
    @LiteralRedact(.hash)
    let password: String
}
```

#### @LiteralRename

Renames properties in generated code:

```swift
@SwiftLiteral
struct User {
    @LiteralRename("displayName")
    let name: String  // Generated as displayName
}
```

### Benefits of Macros

- **Performance**: Skip runtime reflection for annotated types
- **Control**: Fine-grained property filtering and transformation
- **Safety**: Compile-time validation of attributes
- **Ergonomics**: Convenience methods on your types

### Macro-Free Alternative

All functionality is available without macros via the runtime API:

```swift
// Without macros - runtime API
try Literal.export(
    instance: user,
    variableName: "testUser"
)
```

The macros are purely optional enhancements.

## Topics

### Type Attributes

- ``SwiftLiteral``

### Property Attributes

- ``LiteralIgnore``
- ``LiteralRedact``
- ``LiteralRename``