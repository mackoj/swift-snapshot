# ``SwiftLiteral``

Generate type-safe, human-readable Swift source fixtures directly from live runtime values.

## Overview

SwiftLiteral is a comprehensive library for creating compilable Swift fixtures that can be committed, diffed, and reused across your project. It combines a powerful runtime with optional macro-based enhancements for maximum flexibility.

### What is SwiftLiteral?

Instead of serializing data to JSON or binary formats, SwiftLiteral generates actual Swift source code:

```swift
extension User {
    static let testUser: User = User(
        id: 42,
        name: "Alice",
        role: .admin,
        isActive: true
    )
}
```

This approach provides:
- **Type Safety**: Refactors surface compiler errors
- **Human Readable**: Review and understand fixtures like any code
- **Diff Friendly**: Line-by-line semantic diffs in version control
- **Reusable**: Use in tests, previews, documentation, anywhere
- **Zero Production Impact**: DEBUG-only, no release build overhead

### Quick Start

```swift
import SwiftLiteral

// Basic usage - runtime API
let user = User(id: 1, name: "Alice")
let url = try Literal.export(
    instance: user,
    variableName: "testUser"
)

// With macros - enhanced control
@SwiftLiteral
struct Product {
    let id: String
    let name: String
    @LiteralIgnore
    let cache: [String: Any]
}

let product = Product(id: "123", name: "Widget", cache: [:])
try product.writeLiteral(variableName: "testProduct")
```

### Architecture

SwiftLiteral consists of three main components:

- **SwiftLiteralCore**: Runtime library for value rendering and file generation
- **SwiftLiteralMacros**: Compile-time code generation for enhanced features
- **SwiftLiteral**: Public API that combines both components

## Topics

### Getting Started

- <doc:BasicUsage>
- <doc:CustomRenderers>
- <doc:FormattingConfiguration>

### Core Modules

- ``SwiftLiteralCore``
- ``SwiftLiteralMacros``
