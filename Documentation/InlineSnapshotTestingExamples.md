# Inline Snapshot Testing Examples

This document provides examples of how to use inline snapshot testing with SwiftSnapshot using the [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) library.

## Overview

Inline snapshot testing allows you to write assertions directly in your test source code. The snapshot library will automatically update the expected values in your source code when snapshots change.

## Setup

Add the necessary imports to your test file:

```swift
import XCTest
import SnapshotTesting
import InlineSnapshotTesting
@testable import SwiftSnapshot
```

## Examples

### Simple Integer Generation

```swift
func testIntGenerationInline() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: 42,
        variableName: "answer"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension Int { static let answer: Int = 42 }
        
        """
    }
}
```

### String Generation

```swift
func testStringGenerationInline() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: "Hello, World!",
        variableName: "greeting"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension String { static let greeting: String = "Hello, World!" }
        
        """
    }
}
```

### Array Generation

```swift
func testArrayGenerationInline() throws {
    let array = [1, 2, 3]
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: array,
        variableName: "numbers"
    )
    
    // Note: SwiftFormat may use either [Int] or Array<Int> syntax
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension Array<Int> { static let numbers: Array<Int> = [1, 2, 3] }
        
        """
    }
}
```

### Struct Generation

```swift
func testStructGenerationInline() throws {
    struct Point {
        let x: Int
        let y: Int
    }
    
    let point = Point(x: 10, y: 20)
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: point,
        variableName: "origin"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension Point { static let origin: Point = Point(x: 10, y: 20) }
        
        """
    }
}
```

### With Header and Context

```swift
func testWithHeaderAndContextInline() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: true,
        variableName: "isEnabled",
        header: "Generated Test Fixture",
        context: "Feature flag for new functionality"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        // Generated Test Fixture
        
        /// Feature flag for new functionality
        import Foundation
        
        extension Bool { static let isEnabled: Bool = true }
        
        """
    }
}
```

### Optional Values

```swift
func testOptionalGenerationInline() throws {
    let value: String? = "test"
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "optionalValue"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension Optional<String> { static let optionalValue: Optional<String> = "test" }
        
        """
    }
}
```

### Nil Optional

```swift
func testOptionalNilInline() throws {
    let value: String? = nil
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "emptyValue"
    )
    
    assertInlineSnapshot(of: code, as: .lines) {
        """
        import Foundation
        
        extension Optional<String> { static let emptyValue: Optional<String> = nil }
        
        """
    }
}
```

## Important Notes

1. **First Run**: On the first run, inline snapshot tests will fail and show the actual output. The library will then update your source file with the correct snapshot.

2. **Trailing Newlines**: SwiftFormat adds a trailing newline to all files by default. Make sure to include this in your expected snapshots.

3. **Formatting Variations**: SwiftFormat may normalize certain syntax patterns (e.g., `[Int]` to `Array<Int>`). Be aware of these when writing assertions.

4. **Test Isolation**: When running inline snapshot tests, they may need to be run in isolation to avoid conflicts when updating source files.

## Usage Recommendations

- Use inline snapshots for small, frequently changing outputs
- Use file-based snapshots for large outputs
- Run inline snapshot tests separately during development to update snapshots easily
- Commit snapshot changes along with code changes

## See Also

- [swift-snapshot-testing documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [FormattingConfiguration.md](FormattingConfiguration.md) - For configuring code formatting
- [CustomRenderers.md](CustomRenderers.md) - For custom value rendering
