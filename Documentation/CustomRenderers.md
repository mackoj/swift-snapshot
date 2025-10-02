# Custom Renderer Guide

SwiftSnapshot allows you to register custom renderers for your types to control how they are serialized to Swift code.

## Basic Custom Renderer

Register a custom renderer for your type:

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
let code = try SwiftSnapshotRuntime.generateSwiftCode(
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

The render context provides access to formatting and options:

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

```swift
public struct SnapshotRenderContext {
    public let path: [String]        // Breadcrumb path in object graph
    public let formatting: FormatProfile  // Formatting configuration
    public let options: RenderOptions     // Render options
}

public struct RenderOptions {
    public var sortDictionaryKeys: Bool      // Sort dictionary keys
    public var setDeterminism: Bool          // Deterministic set ordering
    public var dataInlineThreshold: Int      // Threshold for inlining Data
    public var forceEnumDotSyntax: Bool      // Force .case syntax for enums
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
let code = try SwiftSnapshotRuntime.generateSwiftCode(
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
