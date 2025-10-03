import Testing
import Foundation

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for SwiftSnapshotError
  @Suite struct SwiftSnapshotErrorTests {
    
    // MARK: - Error Case Tests
    
    /// Test unsupportedType error description
    @Test func unsupportedTypeError() {
      let error = SwiftSnapshotError.unsupportedType("CustomType", path: ["root", "field", "nested"])
      
      let description = error.description
      #expect(description.contains("Unsupported type: CustomType"))
      #expect(description.contains("at path: root → field → nested"))
    }
    
    /// Test unsupportedType error with empty path
    @Test func unsupportedTypeErrorEmptyPath() {
      let error = SwiftSnapshotError.unsupportedType("CustomType", path: [])
      
      let description = error.description
      #expect(description == "Unsupported type: CustomType")
      #expect(!description.contains("at path:"))
    }
    
    /// Test io error description
    @Test func ioError() {
      let error = SwiftSnapshotError.io("Failed to write file")
      
      let description = error.description
      #expect(description == "I/O error: Failed to write file")
    }
    
    /// Test overwriteDisallowed error description
    @Test func overwriteDisallowedError() {
      let url = URL(fileURLWithPath: "/tmp/test.swift")
      let error = SwiftSnapshotError.overwriteDisallowed(url)
      
      let description = error.description
      #expect(description.contains("Overwrite disallowed for file:"))
      #expect(description.contains("/tmp/test.swift"))
    }
    
    /// Test formatting error description
    @Test func formattingError() {
      let error = SwiftSnapshotError.formatting("Invalid configuration")
      
      let description = error.description
      #expect(description == "Formatting error: Invalid configuration")
    }
    
    /// Test reflection error description
    @Test func reflectionError() {
      let error = SwiftSnapshotError.reflection("Cannot reflect type", path: ["User", "address", "zip"])
      
      let description = error.description
      #expect(description.contains("Reflection error: Cannot reflect type"))
      #expect(description.contains("at path: User → address → zip"))
    }
    
    /// Test reflection error with empty path
    @Test func reflectionErrorEmptyPath() {
      let error = SwiftSnapshotError.reflection("Cannot reflect type", path: [])
      
      let description = error.description
      #expect(description == "Reflection error: Cannot reflect type")
      #expect(!description.contains("at path:"))
    }
    
    // MARK: - Error Throwing Tests
    
    /// Test that errors can be caught and matched
    @Test func errorCanBeCaught() {
      do {
        throw SwiftSnapshotError.io("Test error")
      } catch let error as SwiftSnapshotError {
        if case .io(let message) = error {
          #expect(message == "Test error")
        } else {
          Issue.record("Expected .io error")
        }
      } catch {
        Issue.record("Expected SwiftSnapshotError")
      }
    }
    
    /// Test that different error cases can be distinguished
    @Test func errorCasesAreDistinct() {
      let error1 = SwiftSnapshotError.io("test")
      let error2 = SwiftSnapshotError.formatting("test")
      
      // These should have different descriptions
      #expect(error1.description != error2.description)
      #expect(error1.description.contains("I/O error"))
      #expect(error2.description.contains("Formatting error"))
    }
    
    /// Test error with complex path
    @Test func errorWithComplexPath() {
      let path = ["MyStruct", "nestedArray", "[0]", "deepField", "value"]
      let error = SwiftSnapshotError.unsupportedType("UnknownType", path: path)
      
      let description = error.description
      #expect(description.contains("MyStruct → nestedArray → [0] → deepField → value"))
    }
  }
}
