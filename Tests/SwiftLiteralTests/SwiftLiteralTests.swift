import InlineSnapshotTesting
import Testing

@testable import SwiftLiteralCore

extension LiteralTests {
  @Suite struct SwiftLiteralTests {
    init() {
      // Reset configuration between tests
      LiteralConfig.resetToLibraryDefaults()
    }

    // MARK: - Basic Primitive Tests

    @Test func intGeneration() throws {
    let code = try Literal.source(
        of: 42,
        named: "testInt"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    @Test func stringGeneration() throws {
    let code = try Literal.source(
        of: "Hello, World!",
        named: "testString"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension String { static let testString: String = "Hello, World!" }

      """
    }
  }

    @Test func boolGeneration() throws {
    let code = try Literal.source(
        of: true,
        named: "testBool"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Bool { static let testBool: Bool = true }

      """
    }
  }

    @Test func doubleGeneration() throws {
    let code = try Literal.source(
        of: 3.14159,
        named: "testDouble"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Double { static let testDouble: Double = 3.14159 }

      """
    }
  }

    // MARK: - String Escaping Tests

    @Test func stringEscaping() throws {
    let testString = "Hello\nWorld\t\"quoted\""
    let code = try Literal.source(
        of: testString,
        named: "testEscaped"
    )

    assertInlineSnapshot(of: code, as: .description) {
      #"""
      import Foundation

      extension String { static let testEscaped: String = "Hello\nWorld\t\"quoted\"" }

      """#
    }
  }

    // MARK: - Collection Tests

    @Test func arrayGeneration() throws {
    let array = [1, 2, 3, 4, 5]
    let code = try Literal.source(
        of: array,
        named: "testArray"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Array<Int> { static let testArray: Array<Int> = [1, 2, 3, 4, 5] }

      """
    }
  }

    @Test func emptyArrayGeneration() throws {
    let array: [Int] = []
    let code = try Literal.source(
        of: array,
        named: "testEmptyArray"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Array<Int> { static let testEmptyArray: Array<Int> = [] }

      """
    }
  }

    @Test func dictionaryGeneration() throws {
    let dict = ["key1": "value1", "key2": "value2"]
    let code = try Literal.source(
        of: dict,
        named: "testDict"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Dictionary<String, String> {
          static let testDict: Dictionary<String, String> = ["key1": "value1", "key2": "value2"]
      }

      """
    }
  }

    // MARK: - Optional Tests

    @Test func optionalSome() throws {
    let optional: Int? = 42
    let code = try Literal.source(
        of: optional,
        named: "testOptional"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Optional<Int> { static let testOptional: Optional<Int> = 42 }

      """
    }
  }

    @Test func optionalNil() throws {
    let optional: Int? = nil
    let code = try Literal.source(
        of: optional,
        named: "testOptional"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Optional<Int> { static let testOptional: Optional<Int> = nil }

      """
    }
  }

    // MARK: - Foundation Type Tests

    @Test func dateGeneration() throws {
    let date = Date(timeIntervalSince1970: 1234567890.0)
    let code = try Literal.source(
        of: date,
        named: "testDate"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Date { static let testDate: Date = Date(timeIntervalSince1970: 1234567890.0) }

      """
    }
  }

    @Test func uuidGeneration() throws {
    let uuid = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
    let code = try Literal.source(
        of: uuid,
        named: "testUUID"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension UUID {
          static let testUUID: UUID = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
      }

      """
    }
  }

    @Test func urlGeneration() throws {
    let url = URL(string: "https://example.com")!
    let code = try Literal.source(
        of: url,
        named: "testURL"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension URL { static let testURL: URL = URL(string: "https://example.com")! }

      """
    }
  }

    @Test func dataSmallGeneration() throws {
    let data = Data([0x01, 0x02, 0x03])
    let code = try Literal.source(
        of: data,
        named: "testData"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Data { static let testData: Data = Data([0x01, 0x02, 0x03]) }

      """
    }
  }

    @Test func dataLargeGeneration() throws {
    let data = Data(count: 100)
    let code = try Literal.source(
        of: data,
        named: "testData"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Data {
          static let testData: Data = Data(
              base64Encoded:
                  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
          )!
      }

      """
    }
  }

    // MARK: - Struct Reflection Tests

    @Test func simpleStructGeneration() throws {
    struct Person {
      let name: String
      let age: Int
    }

    let person = Person(name: "Alice", age: 30)
    let code = try Literal.source(
        of: person,
        named: "testPerson"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Person { static let testPerson: Person = Person(name: "Alice", age: 30) }

      """
    }
  }

    // MARK: - Enum Tests

    @Test func simpleEnumGeneration() throws {
    enum Status {
      case active
      case inactive
    }

    let status = Status.active
    let code = try Literal.source(
        of: status,
        named: "testStatus"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Status { static let testStatus: Status = .active }

      """
    }
  }

    // MARK: - Header and Context Tests

    @Test func headerGeneration() throws {
    let code = try Literal.source(
        of: 42,
        named: "testInt",
      header: "// Custom Header"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      // Custom Header

      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    @Test func contextGeneration() throws {
    let code = try Literal.source(
        of: 42,
        named: "testInt",
      context: "This is a test integer"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Int {
          /// This is a test integer
          static let testInt: Int = 42
      }

      """
    }
  }

    @Test func globalHeaderConfiguration() throws {
    LiteralConfig.setGlobalHeader("// Global Header")

    let code = try Literal.source(
        of: 42,
        named: "testInt"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      // Global Header

      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    // MARK: - File Export Tests

    @Test func fileExport() throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)

    let url = try Literal.write(
        42,
        named: "testInt",
      directory: tempDir.path
    )
    // Cleanup
    defer { try? FileManager.default.removeItem(at: tempDir) }
    #expect(FileManager.default.fileExists(atPath: url.path))

    let content = try String(contentsOf: url, encoding: .utf8)
    assertInlineSnapshot(of: content, as: .description) {
      """
      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    @Test func fileExportOverwriteDisallowed() throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)

    // First export
    let url1 = try Literal.write(
        42,
        named: "testInt",
      directory: tempDir.path
    )
    // Cleanup
    defer { try? FileManager.default.removeItem(at: tempDir) }
    
    // Verify first export succeeded
    #expect(FileManager.default.fileExists(atPath: url1.path))

    // Exporting again with overwrite disallowed throws. It used to swallow the error
    // and hand back a placeholder URL pointing at /tmp, which read as success.
    #expect(throws: LiteralError.self) {
      try Literal.write(
        43,
        named: "testInt",
        directory: tempDir.path,
        allowOverwrite: false
      )
    }

    // Verify the original file wasn't overwritten
    let content = try String(contentsOf: url1, encoding: .utf8)
    #expect(content.contains("42"))
    #expect(!content.contains("43"))
  }

    // MARK: - Configuration Tests

    @Test func configurationPrecedence() throws {
    // Test that configuration is properly retrieved
    let customProfile = FormatProfile(
      indentStyle: .space,
      indentSize: 2,
      endOfLine: .lf,
      insertFinalNewline: true,
      trimTrailingWhitespace: true
    )
    LiteralConfig.setFormattingProfile(customProfile)

    let retrieved = LiteralConfig.formattingProfile()
    #expect(retrieved.indentSize == 2)
    }

    @Test func renderOptions() throws {
    let options = RenderOptions(
      sortDictionaryKeys: false,
      setDeterminism: true,
      dataInlineThreshold: 16,
      forceEnumDotSyntax: true
    )
    LiteralConfig.setRenderOptions(options)

    let retrieved = LiteralConfig.renderOptions()
    #expect(!retrieved.sortDictionaryKeys)
    }

    // MARK: - Generic Collection Tests

    @Test func genericCollectionSupport() throws {
      struct GenericWrapper<Element>: Collection {
        let elements: [Element]
        
        init(_ elements: [Element]) {
          self.elements = elements
        }
        
        typealias Index = Array<Element>.Index
        var startIndex: Index { elements.startIndex }
        var endIndex: Index { elements.endIndex }
        subscript(position: Index) -> Element { elements[position] }
        func index(after i: Index) -> Index { elements.index(after: i) }
      }
      
      let wrapper = GenericWrapper([1, 2, 3])
      let code = try Literal.source(
        of: wrapper,
        named: "testWrapper"
      )
      
      // Should contain the type name with generic parameter
      #expect(code.contains("GenericWrapper<Int>"))
      // Should contain the elements
      #expect(code.contains("1"))
      #expect(code.contains("2"))
      #expect(code.contains("3"))
    }
  }
}
