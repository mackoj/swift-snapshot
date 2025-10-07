# ``SwiftSnapshotMacros``

Compile-time code generation for enhanced snapshot control and optimized rendering.

## Overview

SwiftSnapshotMacros provides Swift macros that enhance SwiftSnapshot with compile-time features like property filtering, redaction, renaming, and optimized code generation. The macros eliminate the need for runtime reflection in many cases, producing more efficient and predictable snapshots.

### Available Macros

#### @SwiftSnapshot

The main type-level macro that enables snapshot functionality:

```swift
@SwiftSnapshot
struct User {
    let id: Int
    let name: String
}

let user = User(id: 1, name: "Alice")
try user.exportSnapshot(variableName: "testUser")
```

**Features:**
- Generates an `exportSnapshot()` convenience method
- Produces metadata for property introspection
- Enables property-level attributes
- Supports folder organization hints

#### @SnapshotIgnore

Excludes properties from snapshot generation:

```swift
@SwiftSnapshot
struct User {
    let id: String
    let name: String
    @SnapshotIgnore
    let transientCache: [String: Any]
}
```

#### @SnapshotRedact

Redacts sensitive values with masks or hashes:

```swift
@SwiftSnapshot
struct SecureData {
    @SnapshotRedact(.mask("***"))
    let apiKey: String
    
    @SnapshotRedact(.hash)
    let password: String
}
```

#### @SnapshotRename

Renames properties in generated code:

```swift
@SwiftSnapshot
struct User {
    @SnapshotRename("displayName")
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
try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser"
)
```

The macros are purely optional enhancements.

## Topics

### Type Attributes

- ``SwiftSnapshot``

### Property Attributes

- ``SnapshotIgnore``
- ``SnapshotRedact``
- ``SnapshotRename``