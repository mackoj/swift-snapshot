import Testing
import Foundation

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for PathResolver
  @Suite struct PathResolverTests {
    
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - resolveOutputDirectory Tests
    
    /// Test that explicit outputBasePath takes priority
    @Test func resolveOutputDirectoryWithExplicitPath() {
      let explicitPath = "/tmp/custom-snapshots"
      let result = PathResolver.resolveOutputDirectory(
        outputBasePath: explicitPath,
        fileID: #fileID,
        filePath: #filePath
      )
      
      #expect(result.path == explicitPath)
    }
    
    /// Test that global configuration takes priority over environment and defaults
    @Test func resolveOutputDirectoryWithGlobalConfig() {
      let globalRoot = URL(fileURLWithPath: "/tmp/global-snapshots")
      SwiftSnapshotConfig.setGlobalRoot(globalRoot)
      
      let result = PathResolver.resolveOutputDirectory(
        outputBasePath: nil,
        fileID: #fileID,
        filePath: #filePath
      )
      
      #expect(result.path == globalRoot.path)
      
      // Cleanup
      SwiftSnapshotConfig.setGlobalRoot(nil)
    }
    
    /// Test that environment variable is used when no explicit path or global config
    @Test func resolveOutputDirectoryWithEnvironmentVariable() throws {
      let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("env-test-\(UUID())")
      try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: tempDir) }
      
      // Set environment variable
      setenv("SWIFT_SNAPSHOT_ROOT", tempDir.path, 1)
      defer { unsetenv("SWIFT_SNAPSHOT_ROOT") }
      
      let result = PathResolver.resolveOutputDirectory(
        outputBasePath: nil,
        fileID: #fileID,
        filePath: #filePath
      )
      
      #expect(result.path == tempDir.path)
    }
    
    /// Test default behavior when no configuration is provided
    @Test func resolveOutputDirectoryWithDefaultBehavior() {
      // Clear environment variable if set
      unsetenv("SWIFT_SNAPSHOT_ROOT")
      
      let testFilePath: StaticString = "/path/to/Tests/MyTests/SomeTest.swift"
      
      let result = PathResolver.resolveOutputDirectory(
        outputBasePath: nil,
        fileID: #fileID,
        filePath: testFilePath
      )
      
      // Should create __Snapshots__ directory adjacent to test file
      #expect(result.path.hasSuffix("__Snapshots__"))
      #expect(result.path.contains("/path/to/Tests/MyTests"))
    }
    
    // MARK: - resolveFilePath Tests
    
    /// Test resolveFilePath with custom fileName
    @Test func resolveFilePathWithCustomFileName() {
      let outputDir = URL(fileURLWithPath: "/tmp/snapshots")
      
      // Test with .swift extension
      let result1 = PathResolver.resolveFilePath(
        typeName: "User",
        variableName: "testUser",
        fileName: "CustomUser.swift",
        outputDirectory: outputDir
      )
      
      #expect(result1.lastPathComponent == "CustomUser.swift")
      #expect(result1.path.hasPrefix("/tmp/snapshots"))
      
      // Test without .swift extension (should be added)
      let result2 = PathResolver.resolveFilePath(
        typeName: "User",
        variableName: "testUser",
        fileName: "CustomUser",
        outputDirectory: outputDir
      )
      
      #expect(result2.lastPathComponent == "CustomUser.swift")
    }
    
    /// Test resolveFilePath without custom fileName (should use default pattern)
    @Test func resolveFilePathWithDefaultFileName() {
      let outputDir = URL(fileURLWithPath: "/tmp/snapshots")
      
      let result = PathResolver.resolveFilePath(
        typeName: "User",
        variableName: "testUser",
        fileName: nil,
        outputDirectory: outputDir
      )
      
      // Default pattern: TypeName+VariableName.swift
      #expect(result.lastPathComponent == "User+testUser.swift")
      #expect(result.path.hasPrefix("/tmp/snapshots"))
    }
    
    /// Test resolveFilePath with various type and variable name combinations
    @Test func resolveFilePathWithVariousNames() {
      let outputDir = URL(fileURLWithPath: "/tmp/snapshots")
      
      let result1 = PathResolver.resolveFilePath(
        typeName: "Array<String>",
        variableName: "myArray",
        fileName: nil,
        outputDirectory: outputDir
      )
      
      // Angle brackets should be sanitized
      #expect(result1.lastPathComponent == "Array_String_+myArray.swift")
      
      let result2 = PathResolver.resolveFilePath(
        typeName: "Dictionary<String, Int>",
        variableName: "myDict",
        fileName: nil,
        outputDirectory: outputDir
      )
      
      // Angle brackets and commas should be sanitized
      #expect(result2.lastPathComponent == "Dictionary_String__Int_+myDict.swift")
    }
    
    /// Test that generic type names are properly sanitized
    @Test func resolveFilePathWithGenericTypes() {
      let outputDir = URL(fileURLWithPath: "/tmp/snapshots")
      
      // Test User<Kakou>
      let result1 = PathResolver.resolveFilePath(
        typeName: "User<Kakou>",
        variableName: "mock",
        fileName: nil,
        outputDirectory: outputDir
      )
      #expect(result1.lastPathComponent == "User_Kakou_+mock.swift")
      
      // Test nested generics
      let result2 = PathResolver.resolveFilePath(
        typeName: "Array<Dictionary<String, Int>>",
        variableName: "data",
        fileName: nil,
        outputDirectory: outputDir
      )
      #expect(result2.lastPathComponent == "Array_Dictionary_String__Int__+data.swift")
      
      // Test with spaces
      let result3 = PathResolver.resolveFilePath(
        typeName: "Optional<User Model>",
        variableName: "user",
        fileName: nil,
        outputDirectory: outputDir
      )
      #expect(result3.lastPathComponent == "Optional_User_Model_+user.swift")
    }
    
    /// Test that custom fileName is not sanitized (user provided)
    @Test func customFileNameNotSanitized() {
      let outputDir = URL(fileURLWithPath: "/tmp/snapshots")
      
      // When user provides custom fileName, it should be used as-is
      let result = PathResolver.resolveFilePath(
        typeName: "User<Kakou>",
        variableName: "mock",
        fileName: "CustomFixture",
        outputDirectory: outputDir
      )
      
      // Custom file name should not trigger sanitization
      #expect(result.lastPathComponent == "CustomFixture.swift")
    }
    
    /// Test priority order: explicit > global > env > default
    @Test func resolvePriorityOrder() throws {
      let explicitPath = "/tmp/explicit"
      let globalPath = URL(fileURLWithPath: "/tmp/global")
      let envPath = "/tmp/env"
      
      // Set up all levels
      SwiftSnapshotConfig.setGlobalRoot(globalPath)
      setenv("SWIFT_SNAPSHOT_ROOT", envPath, 1)
      defer {
        SwiftSnapshotConfig.setGlobalRoot(nil)
        unsetenv("SWIFT_SNAPSHOT_ROOT")
      }
      
      // Explicit should win
      let result1 = PathResolver.resolveOutputDirectory(
        outputBasePath: explicitPath,
        fileID: #fileID,
        filePath: #filePath
      )
      #expect(result1.path == explicitPath)
      
      // Global should win over env
      let result2 = PathResolver.resolveOutputDirectory(
        outputBasePath: nil,
        fileID: #fileID,
        filePath: #filePath
      )
      #expect(result2.path == globalPath.path)
      
      // Env should win over default
      SwiftSnapshotConfig.setGlobalRoot(nil)
      let result3 = PathResolver.resolveOutputDirectory(
        outputBasePath: nil,
        fileID: #fileID,
        filePath: #filePath
      )
      #expect(result3.path == envPath)
    }
  }
}
