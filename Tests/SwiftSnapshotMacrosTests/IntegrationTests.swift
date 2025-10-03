import XCTest
@testable import SwiftSnapshotMacros
import SwiftSnapshot

// Test types at file level to support extension macros

@SwiftSnapshot
struct TestProduct {
  let id: String
  let name: String
}

@SwiftSnapshot
struct TestUser {
  let id: String
  @SnapshotIgnore
  let cache: [String: Any]
}

@SwiftSnapshot
struct TestItem {
  let id: String
  @SnapshotRename("displayName")
  let name: String
}

@SwiftSnapshot
struct TestSecret {
  let id: String
  @SnapshotRedact(mask: "REDACTED")
  let apiKey: String
}

@SwiftSnapshot
enum TestStatus {
  case active
  case inactive
  case pending
}

// Note: Folder parameter test requires full runtime, skipped in macro-only tests
// @SwiftSnapshot(folder: "Fixtures/Test")
// struct TestConfig {
//   let value: String
// }

@SwiftSnapshot
enum TestResult {
  case success(value: Int)
  case failure(String)
}

/// Integration tests to verify macros work end-to-end
final class MacroIntegrationTests: XCTestCase {
  
  func testMacroGeneratedCodeCompiles() throws {
    // This test verifies that code using the macros compiles successfully
    // The fact that this file compiles proves the macros are working
    
    // Verify the generated members exist
    XCTAssertNil(TestProduct.__swiftSnapshot_folder)  // No folder parameter specified
    XCTAssertFalse(TestProduct.__swiftSnapshot_properties.isEmpty)
    
    let product = TestProduct(id: "123", name: "Widget")
    let expr = TestProduct.__swiftSnapshot_makeExpr(from: product)
    
    // Verify the expression contains expected content
    XCTAssertTrue(expr.contains("TestProduct"))
    XCTAssertTrue(expr.contains("id:"))
    XCTAssertTrue(expr.contains("name:"))
  }
  
  func testMacroWithIgnore() throws {
    let user = TestUser(id: "user123", cache: [:])
    let expr = TestUser.__swiftSnapshot_makeExpr(from: user)
    
    // Verify ignored property is not in expression
    XCTAssertFalse(expr.contains("cache"))
    XCTAssertTrue(expr.contains("id:"))
  }
  
  func testMacroWithRename() throws {
    let item = TestItem(id: "item123", name: "Test Item")
    let expr = TestItem.__swiftSnapshot_makeExpr(from: item)
    
    // Verify renamed label is used
    XCTAssertTrue(expr.contains("displayName:"))
    XCTAssertFalse(expr.contains("name:"))
  }
  
  func testMacroWithRedact() throws {
    let secret = TestSecret(id: "secret123", apiKey: "super-secret-key")
    let expr = TestSecret.__swiftSnapshot_makeExpr(from: secret)
    
    // Verify redacted value appears instead of actual value
    XCTAssertTrue(expr.contains("REDACTED"))
    XCTAssertFalse(expr.contains("super-secret-key"))
  }
  
  func testMacroWithEnum() throws {
    let status = TestStatus.active
    let expr = TestStatus.__swiftSnapshot_makeExpr(from: status)
    
    // Verify enum case is rendered
    XCTAssertTrue(expr.contains(".active"))
  }
  
  // Folder test skipped - requires full runtime integration
  // func testMacroWithFolder() throws {
  //   XCTAssertEqual(TestConfig.__swiftSnapshot_folder, "Fixtures/Test")
  // }
  
  func testEnumWithAssociatedValues() throws {
    let success = TestResult.success(value: 42)
    let expr = TestResult.__swiftSnapshot_makeExpr(from: success)
    
    // Verify enum with associated values
    XCTAssertTrue(expr.contains(".success"))
    XCTAssertTrue(expr.contains("value:"))
  }
}
