import XCTest

@testable import SwiftSnapshot

//final class PerformanceTests: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//        SwiftSnapshotConfig.setGlobalRoot(nil)
//        SwiftSnapshotConfig.setGlobalHeader(nil)
//        SwiftSnapshotConfig.setFormattingProfile(FormatProfile())
//        SwiftSnapshotConfig.setRenderOptions(RenderOptions())
//    }
//
//    // MARK: - Large Array Performance
//
//    func testLargeArrayPerformance() throws {
//        let largeArray = Array(1...10_000)
//
//        measure {
//            do {
//                let _ = try SwiftSnapshotRuntime.generateSwiftCode(
//                    instance: largeArray,
//                    variableName: "largeArray"
//                )
//            } catch {
//                XCTFail("Failed to generate code: \(error)")
//            }
//        }
//    }
//
//    func testLargeArrayRendering() throws {
//        let largeArray = Array(1...10_000)
//        let startTime = Date()
//
//        let code = try SwiftSnapshotRuntime.generateSwiftCode(
//            instance: largeArray,
//            variableName: "largeArray"
//        )
//
//        let elapsed = Date().timeIntervalSince(startTime)
//
//        // Verify it completes within 1 second as per L7 requirements
//        XCTAssertLessThan(elapsed, 1.0, "Large array rendering should complete in less than 1 second")
//        XCTAssertTrue(code.contains("extension Array"))
//
//        print("Large array (10k elements) rendered in \(String(format: "%.3f", elapsed))s")
//    }
//
//    // MARK: - Nested Dictionary Performance
//
//    func testNestedDictionaryPerformance() throws {
//        var nestedDict: [String: Any] = [:]
//
//        // Create deeply nested dictionary structure
//        var current = nestedDict
//        for i in 0..<100 {
//            let key = "level\(i)"
//            current[key] = ["value": i, "next": [:]] as [String: Any]
//            if let next = current[key] as? [String: Any],
//               let nextDict = next["next"] as? [String: Any] {
//                current = nextDict
//            }
//        }
//
//        // This test validates that deeply nested structures can be handled
//        // The actual rendering will use reflection and should complete reasonably
//        measure {
//            do {
//                let _ = try SwiftSnapshotRuntime.generateSwiftCode(
//                    instance: ["root": nestedDict],
//                    variableName: "nestedDict"
//                )
//            } catch {
//                // Deep nesting might fail gracefully, that's acceptable
//            }
//        }
//    }
//
//    // MARK: - Complex Structure Performance
//
//    func testComplexStructurePerformance() throws {
//        struct ComplexModel {
//            let id: Int
//            let name: String
//            let values: [Double]
//            let metadata: [String: String]
//        }
//
//        let models = (0..<1_000).map { i in
//            ComplexModel(
//                id: i,
//                name: "Model \(i)",
//                values: Array(repeating: Double(i), count: 10),
//                metadata: ["key1": "value1", "key2": "value2"]
//            )
//        }
//
//        let startTime = Date()
//
//        let code = try SwiftSnapshotRuntime.generateSwiftCode(
//            instance: models,
//            variableName: "complexModels"
//        )
//
//        let elapsed = Date().timeIntervalSince(startTime)
//
//        XCTAssertTrue(code.contains("ComplexModel"))
//        print("Complex structure (1k models) rendered in \(String(format: "%.3f", elapsed))s")
//    }
//
//    // MARK: - Concurrency Safety Tests
//
//    func testConcurrentExports() throws {
//        let expectation = self.expectation(description: "All concurrent exports complete")
//        expectation.expectedFulfillmentCount = 50
//
//        let tempDir = FileManager.default.temporaryDirectory
//            .appendingPathComponent(UUID().uuidString)
//
//        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
//
//        // Run 50 parallel exports
//        DispatchQueue.concurrentPerform(iterations: 50) { iteration in
//            do {
//                let value = iteration * 100
//                let _ = try SwiftSnapshotRuntime.export(
//                    instance: value,
//                    variableName: "value\(iteration)",
//                    outputBasePath: tempDir.path
//                )
//                expectation.fulfill()
//            } catch {
//                XCTFail("Export \(iteration) failed: \(error)")
//                expectation.fulfill()
//            }
//        }
//
//        wait(for: [expectation], timeout: 10.0)
//
//        // Verify all files were created
//        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
//        XCTAssertEqual(files.count, 50, "Should have created 50 files")
//
//        // Cleanup
//        try? FileManager.default.removeItem(at: tempDir)
//
//        print("Successfully completed 50 concurrent exports")
//    }
//
//    func testConcurrentCodeGeneration() throws {
//        let expectation = self.expectation(description: "All concurrent generations complete")
//        expectation.expectedFulfillmentCount = 50
//
//        var results: [String] = Array(repeating: "", count: 50)
//        let lock = NSLock()
//
//        // Generate code concurrently
//        DispatchQueue.concurrentPerform(iterations: 50) { iteration in
//            do {
//                let code = try SwiftSnapshotRuntime.generateSwiftCode(
//                    instance: iteration,
//                    variableName: "value\(iteration)"
//                )
//
//                lock.lock()
//                results[iteration] = code
//                lock.unlock()
//
//                expectation.fulfill()
//            } catch {
//                XCTFail("Generation \(iteration) failed: \(error)")
//                expectation.fulfill()
//            }
//        }
//
//        wait(for: [expectation], timeout: 10.0)
//
//        // Verify all results are unique and valid
//        let nonEmpty = results.filter { !$0.isEmpty }
//        XCTAssertEqual(nonEmpty.count, 50, "All generations should complete")
//
//        print("Successfully completed 50 concurrent code generations")
//    }
//
//    // MARK: - String Builder Optimization Tests
//
//    func testStringBuilderEfficiency() throws {
//        // Test that string building is efficient for large structures
//        let largeDict = Dictionary(uniqueKeysWithValues: (0..<1000).map { ("key\($0)", "value\($0)") })
//
//        let startTime = Date()
//        let code = try SwiftSnapshotRuntime.generateSwiftCode(
//            instance: largeDict,
//            variableName: "largeDict"
//        )
//        let elapsed = Date().timeIntervalSince(startTime)
//
//        XCTAssertTrue(code.contains("extension Dictionary"))
//        XCTAssertLessThan(elapsed, 1.0, "String building should be efficient")
//
//        print("Large dictionary (1k entries) rendered in \(String(format: "%.3f", elapsed))s")
//    }
//
//    // MARK: - Determinism Under Concurrency
//
//    func testDeterminismUnderConcurrency() throws {
//        let testData = ["key1": "value1", "key2": "value2", "key3": "value3"]
//
//        var results: [String] = []
//        let lock = NSLock()
//
//        // Generate same data multiple times concurrently
//        DispatchQueue.concurrentPerform(iterations: 10) { _ in
//            do {
//                let code = try SwiftSnapshotRuntime.generateSwiftCode(
//                    instance: testData,
//                    variableName: "testData"
//                )
//
//                lock.lock()
//                results.append(code)
//                lock.unlock()
//            } catch {
//                XCTFail("Generation failed: \(error)")
//            }
//        }
//
//        // All results should be identical (deterministic)
//        let uniqueResults = Set(results)
//        XCTAssertEqual(uniqueResults.count, 1, "All concurrent generations should produce identical output")
//
//        print("Determinism verified under concurrent load")
//    }
//}
