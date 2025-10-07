# Best Practices

Proven patterns and guidelines for using SwiftSnapshot effectively in your projects.

## Overview

This guide covers best practices for organizing, naming, and using SwiftSnapshot fixtures to maintain clean, maintainable test and development workflows.

## 🎯 Use Descriptive Names

Choose variable names that clearly describe what the fixture represents and when it should be used.

```swift
// ✅ Good: Clear intent
try user.exportSnapshot(variableName: "activeAdminUser")
try user.exportSnapshot(variableName: "suspendedUserWithPendingOrders")

// ❌ Avoid: Generic or unclear names
try user.exportSnapshot(variableName: "user1")
try user.exportSnapshot(variableName: "testData")
```

**Why it matters**: Descriptive names make fixtures self-documenting and help other developers understand test scenarios at a glance.

## 🗂️ Organize by Domain

Group related fixtures together using folders to maintain clear organization as your fixture library grows.

### Using the Macro

```swift
@SwiftSnapshot(folder: "Fixtures/User")
struct User {
    let id: String
    let name: String
}

@SwiftSnapshot(
    folder: "Fixtures/Orders",
    context: "Order fixtures for e-commerce flow testing"
)
struct Order {
    let id: String
    let items: [OrderItem]
}
```

### Using the Runtime API

```swift
SwiftSnapshotRuntime.export(
    instance: user,
    variableName: "adminUser",
    outputBasePath: "Fixtures/User"
)
```

**Benefits**:
- Easy to locate related fixtures
- Clear domain boundaries
- Scalable as your codebase grows
- Better organization in version control

## 🧪 Leverage in Tests

Use SwiftSnapshot to capture complex test data and create reusable fixtures that improve test reliability and maintainability.

### Capturing Test States

```swift
func testOrderProcessing() throws {
    // Create complex test data
    let order = createComplexOrder()
    
    // Export for future reference
    try order.exportSnapshot(testName: #function)
    
    // Run your test logic
    let result = orderService.process(order)
    
    // Export result for verification
    try result.exportSnapshot(variableName: "processedOrder")
}
```

### Building Reusable Fixtures

```swift
class OrderTests: XCTestCase {
    // Use fixtures across multiple tests
    func testOrderValidation() {
        let order = Order.testOrderProcessing
        XCTAssertTrue(order.isValid())
    }
    
    func testOrderShipping() {
        let order = Order.testOrderProcessing
        XCTAssertNotNil(order.shippingAddress)
    }
}
```

**Benefits**:
- Consistent test data across test suite
- Easier to maintain than hardcoded values
- Self-documenting test scenarios
- Reduces boilerplate in tests

## 🐛 Bug Reproduction & Issue Tracking

Capture exact state when issues occur to reproduce and test against specific bugs.

```swift
func testJiraTicket_ABC123_UserProfileCrash() throws {
    // Reproduce exact conditions from production bug
    let problematicUser = User(
        id: "edge-case-id",
        profile: UserProfile(/* exact data that caused crash */),
        settings: corruptedSettings
    )
    
    // Export the exact context for future regression testing
    try problematicUser.exportSnapshot(testName: #function)
    
    // Test the fix works with this specific data
    XCTAssertNoThrow(userService.processProfile(problematicUser))
}
```

This approach helps maintain a permanent test suite against specific bug reports, ensuring regressions don't reoccur.

### Benefits

- **Permanent record**: Exact reproduction data committed to version control
- **Regression prevention**: Automated tests prevent bugs from returning
- **Team communication**: Other developers can see exact failure conditions
- **Documentation**: Bug fixes include the data that caused the problem

## 🔄 Version Control Integration

Add fixture directories to your repository to track changes over time and catch unintended modifications.

### Recommended .gitignore Configuration

```gitignore
# Don't ignore fixture directories - they're valuable!
# __Fixtures__/
# __Snapshots__/
# Tests/__Fixtures__/

# But ignore temporary debug fixtures
**/debug-fixtures/
**/*_debug_*.swift
```

### Reviewing Fixture Changes

When reviewing pull requests, pay attention to fixture changes:

```diff
 extension Order {
     static let sampleOrder: Order = Order(
         id: "ORD-123",
         items: [...],
-        total: 59.98
+        total: 64.98
     )
 }
```

**Questions to ask**:
- Is this change intentional?
- Does it reflect a bug fix or new feature?
- Are related tests updated?
- Should other fixtures be updated similarly?

## 🚀 Production Build Considerations

**Important**: Exclude `__Fixtures__` and `__Snapshots__` directories from production app archives to keep your deployed app lean.

### Xcode Build Phases

Add a "Run Script" build phase for Release builds:

```bash
# Remove fixture directories from app bundle
find "$TARGET_BUILD_DIR" -name "__Fixtures__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_BUILD_DIR" -name "__Snapshots__" -type d -exec rm -rf {} + 2>/dev/null || true
```

**Configuration**: 
- Add this as a "Run Script" phase after "Copy Bundle Resources"
- Set "Based on configuration" to "Release" only

### Swift Package Manager

Configure conditional compilation for fixture-generating code:

```swift
#if DEBUG
try user.exportSnapshot(testName: #function)
#endif
```

SwiftSnapshot already uses `#if DEBUG` internally, so export calls in production builds become no-ops with minimal overhead.

### Xcode Scheme Configuration

Set up separate schemes for different purposes:

- **Debug**: Include fixtures for testing and development
  - Full SwiftSnapshot functionality enabled
  - Fixture directories included in bundle
  
- **Release**: Exclude fixture generation and directories
  - SwiftSnapshot APIs become no-ops
  - Build script removes fixture directories
  
- **TestFlight/AppStore**: Ensure no fixture code or directories are included
  - Use Release configuration
  - Verify binary size after build
  - Test that no fixture files are in bundle

This keeps your production app size minimal while preserving valuable test data in development.

## 📝 Documentation with Context

Use the `context` parameter to add documentation to your fixtures, making them self-explanatory.

```swift
SwiftSnapshotRuntime.export(
    instance: order,
    variableName: "standardOrder",
    context: """
    Standard order fixture for pricing tests.
    Includes typical items, tax, and shipping costs.
    Total should equal sum of items plus tax and shipping.
    """
)
```

This generates:

```swift
extension Order {
    /// Standard order fixture for pricing tests.
    /// Includes typical items, tax, and shipping costs.
    /// Total should equal sum of items plus tax and shipping.
    static let standardOrder: Order = Order(...)
}
```

**Benefits**:
- Self-documenting fixtures
- Explains fixture purpose and constraints
- Shows up in IDE autocomplete
- Helps future maintainers

## 🎨 SwiftUI Preview Integration

Use fixtures to power your SwiftUI previews with realistic data.

```swift
#Preview("Active User") {
    UserProfileView(user: .activeAdminUser)
}

#Preview("Suspended User") {
    UserProfileView(user: .suspendedUserWithPendingOrders)
}

#Preview("Loading State") {
    UserProfileView(user: .loadingPlaceholder)
}
```

**Benefits**:
- Consistent data between tests and previews
- No duplication of test data
- Easy to create multiple preview scenarios
- Changes to fixtures automatically update previews

## 🔒 Handling Sensitive Data

Never commit real credentials or sensitive data in fixtures. Use redaction features to protect sensitive information.

### Using @SnapshotRedact

```swift
@SwiftSnapshot
struct APIConfig {
    let endpoint: URL
    
    @SnapshotRedact(.mask("***"))
    let apiKey: String
    
    @SnapshotRedact(.hash)
    let secret: String
}
```

### Manual Sanitization

For runtime API, sanitize before exporting:

```swift
var sanitizedUser = user
sanitizedUser.creditCard = "****-****-****-1234"
sanitizedUser.ssn = "***-**-1234"

try sanitizedUser.exportSnapshot(
    variableName: "testUser",
    context: "Test user with sanitized PII"
)
```

## 🎯 Naming Conventions

Establish consistent naming conventions across your team.

### Recommended Patterns

```swift
// Pattern: [State][Role][Scenario]
Order.activeOrderWithShipping
Order.cancelledOrderWithRefund

// Pattern: [TestName][Purpose]
User.testUserCreation
User.testUserValidation_EdgeCase

// Pattern: [Domain][Variant]
Product.sampleProduct_InStock
Product.sampleProduct_OutOfStock
```

### File Naming

```swift
// Group related fixtures in same file
SwiftSnapshotRuntime.export(
    instance: admin,
    variableName: "adminUser",
    fileName: "User+Fixtures"
)

SwiftSnapshotRuntime.export(
    instance: guest,
    variableName: "guestUser",
    fileName: "User+Fixtures"  // Same file
)
```

## 🧹 Maintenance

### Regular Cleanup

Periodically review and remove unused fixtures:

```bash
# Find fixtures not referenced in tests
grep -r "\.testFixtureName" Tests/ || echo "Unused fixture detected"
```

### Update with Refactoring

When refactoring types, the compiler will help identify broken fixtures:

```swift
// After renaming User.fullName from User.name
// Fixtures won't compile - update them!
extension User {
    static let testUser: User = User(
        id: 1,
        fullName: "Alice"  // Compiler ensures you update this
    )
}
```

## 📊 Performance Considerations

### Keep Fixtures Focused

```swift
// ✅ Good: Minimal data needed for test
let user = User(id: 1, name: "Test")
try user.exportSnapshot(variableName: "minimalUser")

// ❌ Avoid: Unnecessarily complex fixtures
let user = User(
    // 50 properties...
    // 20 nested objects...
    // Large collections...
)
```

### Lazy Loading for Large Fixtures

For very large fixtures, consider lazy initialization:

```swift
extension Dataset {
    static var largeDataset: Dataset {
        // Only loaded when actually accessed
        Dataset(/* large data */)
    }
}
```

## See Also

- <doc:BasicUsage> - Getting started with SwiftSnapshot
- <doc:CustomRenderers> - Handling special types
- ``SwiftSnapshotRuntime`` - Runtime API reference
- ``SwiftSnapshot`` - Macro API reference
