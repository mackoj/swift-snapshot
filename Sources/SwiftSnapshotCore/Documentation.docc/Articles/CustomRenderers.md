# Custom Renderer Guide

Learn how to register custom renderers to control how your types are converted to Swift code.

## Overview

SwiftSnapshot's ``SnapshotRendererRegistry`` allows you to register custom rendering logic for types that:
- Need special initialization syntax
- Should be rendered differently than the default reflection-based approach
- Have properties that should be excluded or transformed
- Require custom formatting or validation

Custom renderers are checked **before** built-in renderers, giving you complete control over type serialization.

## Basic Custom Renderer

Register a custom renderer using ``SnapshotRendererRegistry/register(_:render:)``:

```swift
import SwiftSnapshot
import SwiftSyntax

struct MyCustomType {
    let value: String
    let count: Int
}

// Register custom renderer
SnapshotRendererRegistry.register(MyCustomType.self) { instance, context in
    // Return a SwiftSyntax ExprSyntax representing your type
    ExprSyntax(stringLiteral: """
    MyCustomType(
        value: "\(instance.value)",
        count: \(instance.count)
    )
    """)
}

// Now use it
let custom = MyCustomType(value: "test", count: 42)
let url = SwiftSnapshotRuntime.export(
    instance: custom,
    variableName: "myCustom"
)
```

## Auto-Registration Pattern

Use the auto-registration helper for cleaner code:

```swift
// Define your custom renderer at module scope
private let _ = autoregister(MyCustomType.self) { value, ctx in
    ExprSyntax(stringLiteral: """
    MyCustomType(
        value: "\(value.value)",
        count: \(value.count)
    )
    """)
}
```

## Using Render Context

The ``SnapshotRenderContext`` parameter provides access to formatting and options:

```swift
SnapshotRendererRegistry.register(MyType.self) { instance, context in
    // Access the path for debugging
    let path = context.path.joined(separator: ".")
    
    // Access formatting profile
    let indent = context.formatting.indent(level: 1)
    
    // Access render options
    if context.options.sortDictionaryKeys {
        // Apply custom sorting logic
    }
    
    return ExprSyntax(stringLiteral: "MyType(...)")
}
```

## Render Context Properties

The ``SnapshotRenderContext`` provides three key properties:

- **path**: Array of property names showing location in the object graph
- **formatting**: ``FormatProfile`` with indentation, line endings, and whitespace rules
- **options**: ``RenderOptions`` controlling sorting, determinism, and thresholds

Example usage:

```swift
SnapshotRendererRegistry.register(MyType.self) { value, context in
    // Use path for error reporting
    print("Rendering at: \(context.path.joined(separator: "."))")
    
    // Use formatting for consistent indentation
    let indent = context.formatting.indent(level: 1)
    
    // Use options for conditional logic
    let sorted = context.options.sortDictionaryKeys
    
    return ExprSyntax(stringLiteral: "MyType(...)")
}
```

## Complex Examples

### Example 1: URL with Validation

```swift
SnapshotRendererRegistry.register(URL.self) { url, context in
    let urlString = url.absoluteString
    return ExprSyntax(stringLiteral: "URL(string: \"\(urlString)\")!")
}
```

### Example 2: Date with Custom Format

```swift
import Foundation

SnapshotRendererRegistry.register(Date.self) { date, context in
    let timeInterval = date.timeIntervalSince1970
    return ExprSyntax(stringLiteral: "Date(timeIntervalSince1970: \(timeInterval))")
}
```

### Example 3: Complex Type with Nested Properties

```swift
struct Address {
    let street: String
    let city: String
    let zipCode: String
}

SnapshotRendererRegistry.register(Address.self) { address, context in
    let indent = context.formatting.indent(level: 1)
    return ExprSyntax(stringLiteral: """
    Address(
    \(indent)street: "\(address.street)",
    \(indent)city: "\(address.city)",
    \(indent)zipCode: "\(address.zipCode)"
    )
    """)
}
```

### Example 4: Types with Transformed or Destroyed Initialization Values

Some types transform their input during initialization, making it impossible to reconstruct them from the original value. In these cases, you must use a custom renderer that references an alternative initializer.

```swift
@Snapshot
struct Bizarro {
    let transformed: Int
    
    // Primary initializer transforms input - original value is lost
    public init(_ content: String) {
        self.transformed = content.hash
    }
    
    // Alternative initializer for reconstruction
    init(whyAreYouSoooMean transformed: Int) {
        self.transformed = transformed
    }
}

// Register custom renderer using the alternative initializer
SnapshotRendererRegistry.register(Bizarro.self) { instance, context in
    ExprSyntax(stringLiteral: """
    Bizarro(whyAreYouSoooMean: \(instance.transformed))
    """)
}

// Now snapshots work correctly
let bizarre = Bizarro("Pikachu")
let url = try bizarre.exportSnapshot(variableName: "crazyyyyy")
// Generates: Bizarro(whyAreYouSoooMean: 8234567890)
```

This pattern is essential for types that:
- Compute hashes or derived values during initialization
- Encrypt or encode input data
- Perform lossy transformations (e.g., rounding, truncation)
- Convert between incompatible representations

**Key Guidelines:**
- Provide an alternative initializer that accepts the stored/transformed values
- Use descriptive parameter names to clarify the alternative initialization path
- Document the relationship between initializers in your type's documentation
- Ensure the alternative initializer is accessible from your test code

## Best Practices

1. **Register Early**: Register custom renderers before using them
2. **Thread Safety**: Registration is thread-safe via internal locking
3. **Use Context**: Leverage context for formatting consistency
4. **Error Handling**: Renderers should not throw; return valid Swift code
5. **Deterministic**: Ensure output is deterministic for reproducibility

## Bootstrap System

For types requiring early registration:

```swift
// In your module initialization
SnapshotRendererRegistry.bootstrap()

// Your custom renderers are registered automatically via auto-registration
```

## Troubleshooting

### Renderer Not Applied

Ensure registration happens before usage:

```swift
// Register
SnapshotRendererRegistry.register(MyType.self) { value, ctx in
    // ...
}

// Then use
let url = SwiftSnapshotRuntime.export(
    instance: myInstance,
    variableName: "myVar"
)
```

### Type Ambiguity

For generic types, be specific:

```swift
// Register for specific generic instantiation
SnapshotRendererRegistry.register([MyType].self) { array, context in
    // Custom array rendering
}
```
