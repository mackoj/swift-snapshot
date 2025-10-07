# ``SwiftSnapshot``

Generate type-safe, human-readable Swift source fixtures directly from live runtime values.

## Overview

SwiftSnapshot is a comprehensive library for creating compilable Swift fixtures that can be committed, diffed, and reused across your project. It combines a powerful runtime with optional macro-based enhancements for maximum flexibility.

### What is SwiftSnapshot?

Instead of serializing data to JSON or binary formats, SwiftSnapshot generates actual Swift source code:

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
import SwiftSnapshot

// Basic usage - runtime API
let user = User(id: 1, name: "Alice")
let url = try SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "testUser"
)

// With macros - enhanced control
@Snapshot
struct Product {
    let id: String
    let name: String
    @SnapshotIgnore
    let cache: [String: Any]
}

let product = Product(id: "123", name: "Widget", cache: [:])
try product.exportSnapshot(variableName: "testProduct")
```

### Architecture

SwiftSnapshot consists of three main components:

- **SwiftSnapshotCore**: Runtime library for value rendering and file generation
- **SwiftSnapshotMacros**: Compile-time code generation for enhanced features
- **SwiftSnapshot**: Public API that combines both components

## Topics

### Getting Started

- <doc:BasicUsage>
- <doc:CustomRenderers>
- <doc:FormattingConfiguration>

### Core Modules

- ``SwiftSnapshotCore``
- ``SwiftSnapshotMacros``
