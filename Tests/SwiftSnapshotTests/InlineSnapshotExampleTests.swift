import XCTest
import SnapshotTesting
import InlineSnapshotTesting
@testable import SwiftSnapshot

/// Example tests demonstrating inline snapshot testing functionality
///
/// These tests use the swift-snapshot-testing library's inline snapshot feature
/// to verify generated Swift code directly within the test source.
final class InlineSnapshotExampleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset configuration between tests
        SwiftSnapshotConfig.setGlobalRoot(nil)
        SwiftSnapshotConfig.setGlobalHeader(nil)
        SwiftSnapshotConfig.setFormattingProfile(FormatProfile())
        SwiftSnapshotConfig.setRenderOptions(RenderOptions())
    }
    
    // MARK: - Inline Snapshot Tests
    
    /// Test simple integer generation with inline snapshot
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
    
    /// Test string generation with inline snapshot
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
    
    /// Test array generation with inline snapshot
    func testArrayGenerationInline() throws {
        let array = [1, 2, 3]
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
            instance: array,
            variableName: "numbers"
        )
        
        // The formatter may use either [Int] or Array<Int> syntax
        // For inline snapshots, we just verify the output is as expected
        assertInlineSnapshot(of: code, as: .lines) {
            """
            import Foundation
            
            extension Array<Int> { static let numbers: Array<Int> = [1, 2, 3] }
            
            """
        }
    }
    
    /// Test struct with inline snapshot
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
    
    /// Test with header and context using inline snapshot
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
    
    /// Test optional value with inline snapshot
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
    
    /// Test nil optional with inline snapshot
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
}
