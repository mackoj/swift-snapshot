import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshot

extension SnapshotTests {
  @Suite struct SwiftSnapshotTests {
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.setGlobalRoot(nil)
      SwiftSnapshotConfig.setGlobalHeader(nil)
      SwiftSnapshotConfig.setFormattingProfile(FormatProfile())
      SwiftSnapshotConfig.setRenderOptions(RenderOptions())
    }

    // MARK: - Basic Primitive Tests

    @Test func intGeneration() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 42,
      variableName: "testInt"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    @Test func stringGeneration() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: "Hello, World!",
      variableName: "testString"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension String { static let testString: String = "Hello, World!" }

      """
    }
  }

    @Test func boolGeneration() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: true,
      variableName: "testBool"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Bool { static let testBool: Bool = true }

      """
    }
  }

    @Test func doubleGeneration() throws {
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 3.14159,
      variableName: "testDouble"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: testString,
      variableName: "testEscaped"
    )

    assertInlineSnapshot(of: code, as: .description) {
      #"""
      import Foundation

      extension String { static let testEscaped: String = #"Hello\nWorld\t\"quoted\""# }

      """#
    }
  }

    // MARK: - Collection Tests

    @Test func arrayGeneration() throws {
    let array = [1, 2, 3, 4, 5]
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: array,
      variableName: "testArray"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: array,
      variableName: "testEmptyArray"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: dict,
      variableName: "testDict"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: optional,
      variableName: "testOptional"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: optional,
      variableName: "testOptional"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: date,
      variableName: "testDate"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: uuid,
      variableName: "testUUID"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: url,
      variableName: "testURL"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: data,
      variableName: "testData"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: data,
      variableName: "testData"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: person,
      variableName: "testPerson"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: status,
      variableName: "testStatus"
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 42,
      variableName: "testInt",
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
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 42,
      variableName: "testInt",
      context: "This is a test integer"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      /// This is a test integer
      import Foundation

      extension Int { static let testInt: Int = 42 }

      """
    }
  }

    @Test func globalHeaderConfiguration() throws {
    SwiftSnapshotConfig.setGlobalHeader("// Global Header")

    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 42,
      variableName: "testInt"
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

    let url = try SwiftSnapshotRuntime.export(
      instance: 42,
      variableName: "testInt",
      outputBasePath: tempDir.path
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
    _ = try SwiftSnapshotRuntime.export(
      instance: 42,
      variableName: "testInt",
      outputBasePath: tempDir.path
    )
    // Cleanup
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Second export with overwrite disallowed should throw
    #expect(throws: (any Error).self) {
      try SwiftSnapshotRuntime.export(
        instance: 43,
        variableName: "testInt",
        outputBasePath: tempDir.path,
        allowOverwrite: false
      )
    }
  }

    // MARK: - Configuration Tests

    @Test func configurationPrecedence() throws {
    // Test that configuration is properly retrieved
    let customProfile = FormatProfile(indentSize: 2)
    SwiftSnapshotConfig.setFormattingProfile(customProfile)

    let retrieved = SwiftSnapshotConfig.formattingProfile()
    #expect(retrieved.indentSize == 2)
    }

    @Test func renderOptions() throws {
    var options = RenderOptions()
    options.sortDictionaryKeys = false
    SwiftSnapshotConfig.setRenderOptions(options)

    let retrieved = SwiftSnapshotConfig.renderOptions()
    #expect(!retrieved.sortDictionaryKeys)
    }
  }
}
