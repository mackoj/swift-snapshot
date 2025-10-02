import XCTest
@testable import SwiftSnapshot

final class SwiftSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset configuration between tests
        SwiftSnapshotConfig.setGlobalRoot(nil)
        SwiftSnapshotConfig.setGlobalHeader(nil)
        SwiftSnapshotConfig.setFormattingProfile(FormatProfile())
        SwiftSnapshotConfig.setRenderOptions(RenderOptions())
    }
    
    // MARK: - Basic Primitive Tests
    
    func testIntGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: 42,
            variableName: "testInt"
        )
        
        XCTAssertTrue(code.contains("extension Int"))
        XCTAssertTrue(code.contains("static let testInt: Int = 42"))
        XCTAssertTrue(code.contains("import Foundation"))
    }
    
    func testStringGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: "Hello, World!",
            variableName: "testString"
        )
        
        XCTAssertTrue(code.contains("extension String"))
        XCTAssertTrue(code.contains("static let testString: String = \"Hello, World!\""))
    }
    
    func testBoolGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: true,
            variableName: "testBool"
        )
        
        XCTAssertTrue(code.contains("extension Bool"))
        XCTAssertTrue(code.contains("static let testBool: Bool = true"))
    }
    
    func testDoubleGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: 3.14159,
            variableName: "testDouble"
        )
        
        XCTAssertTrue(code.contains("extension Double"))
        XCTAssertTrue(code.contains("static let testDouble: Double"))
        XCTAssertTrue(code.contains("3.14159"))
    }
    
    // MARK: - String Escaping Tests
    
    func testStringEscaping() throws {
        let testString = "Hello\nWorld\t\"quoted\""
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: testString,
            variableName: "testEscaped"
        )
        
        XCTAssertTrue(code.contains("\\n"))
        XCTAssertTrue(code.contains("\\t"))
        XCTAssertTrue(code.contains("\\\""))
    }
    
    // MARK: - Collection Tests
    
    func testArrayGeneration() throws {
        let array = [1, 2, 3, 4, 5]
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: array,
            variableName: "testArray"
        )
        
        XCTAssertTrue(code.contains("extension [Int]"))
        XCTAssertTrue(code.contains("testArray"))
        // Should contain the numbers
        XCTAssertTrue(code.contains("1"))
        XCTAssertTrue(code.contains("5"))
    }
    
    func testEmptyArrayGeneration() throws {
        let array: [Int] = []
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: array,
            variableName: "testEmptyArray"
        )
        
        XCTAssertTrue(code.contains("[]"))
    }
    
    func testDictionaryGeneration() throws {
        let dict = ["key1": "value1", "key2": "value2"]
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: dict,
            variableName: "testDict"
        )
        
        XCTAssertTrue(code.contains("extension [String: String]"))
        // Keys should be present
        XCTAssertTrue(code.contains("key1"))
        XCTAssertTrue(code.contains("key2"))
    }
    
    // MARK: - Optional Tests
    
    func testOptionalSome() throws {
        let optional: Int? = 42
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: optional,
            variableName: "testOptional"
        )
        
        XCTAssertTrue(code.contains("42"))
        XCTAssertFalse(code.contains("nil"))
    }
    
    func testOptionalNil() throws {
        let optional: Int? = nil
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: optional,
            variableName: "testOptional"
        )
        
        XCTAssertTrue(code.contains("nil"))
    }
    
    // MARK: - Foundation Type Tests
    
    func testDateGeneration() throws {
        let date = Date(timeIntervalSince1970: 1234567890.0)
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: date,
            variableName: "testDate"
        )
        
        XCTAssertTrue(code.contains("Date(timeIntervalSince1970:"))
        XCTAssertTrue(code.contains("1234567890"))
    }
    
    func testUUIDGeneration() throws {
        let uuid = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: uuid,
            variableName: "testUUID"
        )
        
        XCTAssertTrue(code.contains("UUID(uuidString:"))
        XCTAssertTrue(code.contains("12345678-1234-1234-1234-123456789012"))
    }
    
    func testURLGeneration() throws {
        let url = URL(string: "https://example.com")!
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: url,
            variableName: "testURL"
        )
        
        XCTAssertTrue(code.contains("URL(string:"))
        XCTAssertTrue(code.contains("example.com"))
    }
    
    func testDataSmallGeneration() throws {
        let data = Data([0x01, 0x02, 0x03])
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: data,
            variableName: "testData"
        )
        
        XCTAssertTrue(code.contains("Data(["))
        XCTAssertTrue(code.contains("0x01"))
    }
    
    func testDataLargeGeneration() throws {
        let data = Data(count: 100)
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: data,
            variableName: "testData"
        )
        
        XCTAssertTrue(code.contains("base64Encoded:"))
    }
    
    // MARK: - Struct Reflection Tests
    
    func testSimpleStructGeneration() throws {
        struct Person {
            let name: String
            let age: Int
        }
        
        let person = Person(name: "Alice", age: 30)
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: person,
            variableName: "testPerson"
        )
        
        XCTAssertTrue(code.contains("extension Person"))
        XCTAssertTrue(code.contains("Person("))
        XCTAssertTrue(code.contains("name:"))
        XCTAssertTrue(code.contains("Alice"))
        XCTAssertTrue(code.contains("age:"))
        XCTAssertTrue(code.contains("30"))
    }
    
    // MARK: - Enum Tests
    
    func testSimpleEnumGeneration() throws {
        enum Status {
            case active
            case inactive
        }
        
        let status = Status.active
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: status,
            variableName: "testStatus"
        )
        
        XCTAssertTrue(code.contains("extension Status"))
        XCTAssertTrue(code.contains(".active"))
    }
    
    // MARK: - Header and Context Tests
    
    func testHeaderGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: 42,
            variableName: "testInt",
            header: "// Custom Header"
        )
        
        XCTAssertTrue(code.contains("// Custom Header"))
    }
    
    func testContextGeneration() throws {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: 42,
            variableName: "testInt",
            context: "This is a test integer"
        )
        
        XCTAssertTrue(code.contains("/// This is a test integer"))
    }
    
    func testGlobalHeaderConfiguration() throws {
        SwiftSnapshotConfig.setGlobalHeader("// Global Header")
        
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: 42,
            variableName: "testInt"
        )
        
        XCTAssertTrue(code.contains("// Global Header"))
    }
    
    // MARK: - File Export Tests
    
    func testFileExport() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let url = try SwiftSnapshotRuntime.export(
            instance: 42,
            variableName: "testInt",
            outputBasePath: tempDir.path
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("extension Int"))
        XCTAssertTrue(content.contains("static let testInt: Int = 42"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    func testFileExportOverwriteDisallowed() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        // First export
        _ = try SwiftSnapshotRuntime.export(
            instance: 42,
            variableName: "testInt",
            outputBasePath: tempDir.path
        )
        
        // Second export with overwrite disallowed should throw
        XCTAssertThrowsError(
            try SwiftSnapshotRuntime.export(
                instance: 43,
                variableName: "testInt",
                outputBasePath: tempDir.path,
                allowOverwrite: false
            )
        ) { error in
            XCTAssertTrue(error is SwiftSnapshotError)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationPrecedence() throws {
        // Test that configuration is properly retrieved
        let customProfile = FormatProfile(indentSize: 2)
        SwiftSnapshotConfig.setFormattingProfile(customProfile)
        
        let retrieved = SwiftSnapshotConfig.formattingProfile()
        XCTAssertEqual(retrieved.indentSize, 2)
    }
    
    func testRenderOptions() throws {
        var options = RenderOptions()
        options.sortDictionaryKeys = false
        SwiftSnapshotConfig.setRenderOptions(options)
        
        let retrieved = SwiftSnapshotConfig.renderOptions()
        XCTAssertFalse(retrieved.sortDictionaryKeys)
    }
}
