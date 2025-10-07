import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for format configuration loading from .swift-format and .editorconfig files
  @Suite struct FormattingConfigTests {
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - Configuration Loading Tests

    /// Test loading configuration from .editorconfig
    @Test func editorConfigLoading() throws {
    // Create a temporary .editorconfig file
    let tempDir = FileManager.default.temporaryDirectory
    let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")

    let configContent = """
      [*]
      indent_style = space
      indent_size = 2
      end_of_line = lf
      insert_final_newline = true
      trim_trailing_whitespace = true
      """

    try configContent.write(to: configURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: configURL) }

    // Set the config source
    SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))

    // Verify the config source is set
    let source = SwiftSnapshotConfig.getFormatConfigSource()
    #expect(source != nil)

    // Load and verify profile
    let profile = try FormatConfigLoader.loadProfile(from: source)
    #expect(profile.indentSize == 2)
    #expect(profile.indentStyle == .space)
    #expect(profile.endOfLine == .lf)
    #expect(profile.insertFinalNewline)
    #expect(profile.trimTrailingWhitespace)
    }

    /// Test loading configuration from .swift-format
    @Test func swiftFormatConfigLoading() throws {
    // Create a temporary .swift-format file
    let tempDir = FileManager.default.temporaryDirectory
    let configURL = tempDir.appendingPathComponent("test-\(UUID()).swift-format")

    let configContent = """
      {
        "version" : 1,
        "lineLength" : 100,
        "indentation" : {
          "spaces" : 2
        },
        "maximumBlankLines" : 1
      }
      """

    try configContent.write(to: configURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: configURL) }

    // Set the config source
    SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(configURL))

    // Verify the config source is set
    let source = SwiftSnapshotConfig.getFormatConfigSource()
    #expect(source != nil)

    if case .swiftFormat(let url) = source {
      #expect(url == configURL)
    } else {
      Issue.record("Expected swiftFormat config source")
    }
    }

    /// Test that formatting respects configuration
    @Test func formattingWithCustomConfig() throws {
    // Create a profile with custom indentation
    let customProfile = FormatProfile(
      indentStyle: .space,
      indentSize: 2,
      endOfLine: .lf,
      insertFinalNewline: true,
      trimTrailingWhitespace: true
    )

    SwiftSnapshotConfig.setFormattingProfile(customProfile)

    // Generate code
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: 42,
      variableName: "testValue"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Int { static let testValue: Int = 42 }

      """
    }
    }

    /// Test configuration precedence
    @Test func configurationPrecedence() throws {
    // Create a temporary .editorconfig file
    let tempDir = FileManager.default.temporaryDirectory
    let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")

    let configContent = """
      [*]
      indent_size = 8
      """

    try configContent.write(to: configURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: configURL) }

    // Set config source (this should take precedence over profile)
    SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))

    // Also set a different profile
    let customProfile = FormatProfile(
      indentStyle: .space,
      indentSize: 2,
      endOfLine: .lf,
      insertFinalNewline: true,
      trimTrailingWhitespace: true
    )
    SwiftSnapshotConfig.setFormattingProfile(customProfile)

    // The config file should be used by the formatter when present
    let source = SwiftSnapshotConfig.getFormatConfigSource()
    let loadedProfile = try FormatConfigLoader.loadProfile(from: source)

    // Config file should override
    #expect(loadedProfile.indentSize == 8)
    }

    /// Test default configuration when no config file is specified
    @Test func defaultConfiguration() throws {
    // Don't set any config source
    SwiftSnapshotConfig.setFormatConfigSource(nil)

    // Generate code with default configuration
    let code = try SwiftSnapshotRuntime.generateSwiftCode(
      instance: [1, 2, 3],
      variableName: "numbers"
    )

    assertInlineSnapshot(of: code, as: .description) {
      """
      import Foundation

      extension Array<Int> { static let numbers: Array<Int> = [1, 2, 3] }

      """
    }
    }

    /// Test FormatConfigLoader.findConfigFile
    @Test func configFileFinding() throws {
    // Create a temporary directory structure
    let tempDir = FileManager.default.temporaryDirectory
    let testDir = tempDir.appendingPathComponent("test-\(UUID())")
    let subDir = testDir.appendingPathComponent("subdir")

    try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: testDir) }

    // Create a config file in the parent directory
    let configURL = testDir.appendingPathComponent(".editorconfig")
    try "test".write(to: configURL, atomically: true, encoding: .utf8)

    // Search from subdirectory
    let foundURL = FormatConfigLoader.findConfigFile(
      startingFrom: subDir,
      named: ".editorconfig"
    )

    // Should find the config file in parent directory
    #expect(foundURL != nil)
    #expect(foundURL?.path == configURL.path)
    }
    
    /// Test findConfigFile when file doesn't exist
    @Test func configFileNotFound() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let testDir = tempDir.appendingPathComponent("test-\(UUID())")
      
      try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: testDir) }
      
      // Search for non-existent file
      let foundURL = FormatConfigLoader.findConfigFile(
        startingFrom: testDir,
        named: ".nonexistent"
      )
      
      #expect(foundURL == nil)
    }
    
    // MARK: - EditorConfig Advanced Tests
    
    /// Test loading .editorconfig with tab indent style
    @Test func editorConfigWithTabIndent() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")
      
      let configContent = """
        [*]
        indent_style = tab
        indent_size = 4
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      #expect(profile.indentStyle == .tab)
      #expect(profile.indentSize == 4)
    }
    
    /// Test loading .editorconfig with CRLF line endings
    @Test func editorConfigWithCRLF() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")
      
      let configContent = """
        [*]
        end_of_line = crlf
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      #expect(profile.endOfLine == .crlf)
    }
    
    /// Test loading .editorconfig with false boolean flags
    @Test func editorConfigWithFalseFlags() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")
      
      let configContent = """
        [*]
        insert_final_newline = false
        trim_trailing_whitespace = false
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      #expect(profile.insertFinalNewline == false)
      #expect(profile.trimTrailingWhitespace == false)
    }
    
    /// Test loading .editorconfig with section matching
    @Test func editorConfigWithSections() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")
      
      let configContent = """
        # Default section
        indent_size = 4
        
        [*.swift]
        indent_size = 2
        indent_style = space
        
        [*.md]
        indent_size = 8
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      // Should use the [*.swift] section
      #expect(profile.indentSize == 2)
      #expect(profile.indentStyle == .space)
    }
    
    /// Test loading .editorconfig with comments
    @Test func editorConfigWithComments() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).editorconfig")
      
      let configContent = """
        # This is a comment
        [*]
        # Another comment
        indent_size = 3
        ; Semicolon comment
        indent_style = space
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      #expect(profile.indentSize == 3)
      #expect(profile.indentStyle == .space)
    }
    
    // MARK: - SwiftFormat Advanced Tests
    
    /// Test loading .swift-format with indent field
    @Test func swiftFormatWithIndentField() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).swift-format")
      
      let configContent = """
        {
          "version" : 1,
          "indent" : 3
        }
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .swiftFormat(configURL))
      
      #expect(profile.indentSize == 3)
      #expect(profile.indentStyle == .space)
    }
    
    /// Test loading .swift-format with tabWidth field
    @Test func swiftFormatWithTabWidth() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).swift-format")
      
      let configContent = """
        {
          "version" : 1,
          "tabWidth" : 8
        }
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      let profile = try FormatConfigLoader.loadProfile(from: .swiftFormat(configURL))
      
      #expect(profile.indentSize == 8)
    }
    
    /// Test loading .swift-format with invalid JSON
    @Test func swiftFormatWithInvalidJSON() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).swift-format")
      
      let configContent = """
        {
          "version" : 1,
          "indent" : 
        }
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      // Should throw an error for invalid JSON
      #expect(throws: Error.self) {
        try FormatConfigLoader.loadProfile(from: .swiftFormat(configURL))
      }
    }
    
    /// Test loading .swift-format with non-dictionary JSON
    @Test func swiftFormatWithNonDictionary() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("test-\(UUID()).swift-format")
      
      let configContent = """
        ["array", "instead", "of", "object"]
        """
      
      try configContent.write(to: configURL, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: configURL) }
      
      // Should throw a formatting error
      #expect(throws: SwiftSnapshotError.self) {
        try FormatConfigLoader.loadProfile(from: .swiftFormat(configURL))
      }
    }
    
    // MARK: - Missing File Fallback Tests
    
    /// Test that missing .swift-format file falls back to defaults
    @Test func missingSwiftFormatFallback() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("nonexistent-\(UUID()).swift-format")
      
      // Ensure file doesn't exist
      #expect(!FileManager.default.fileExists(atPath: configURL.path))
      
      // Should not throw, should return defaults
      let profile = try FormatConfigLoader.loadProfile(from: .swiftFormat(configURL))
      
      // Verify we got library defaults
      let defaults = SwiftSnapshotConfig.libraryDefaultFormatProfile()
      #expect(profile.indentSize == defaults.indentSize)
      #expect(profile.indentStyle == defaults.indentStyle)
      #expect(profile.endOfLine == defaults.endOfLine)
      #expect(profile.insertFinalNewline == defaults.insertFinalNewline)
      #expect(profile.trimTrailingWhitespace == defaults.trimTrailingWhitespace)
    }
    
    /// Test that missing .editorconfig file falls back to defaults
    @Test func missingEditorConfigFallback() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("nonexistent-\(UUID()).editorconfig")
      
      // Ensure file doesn't exist
      #expect(!FileManager.default.fileExists(atPath: configURL.path))
      
      // Should not throw, should return defaults
      let profile = try FormatConfigLoader.loadProfile(from: .editorconfig(configURL))
      
      // Verify we got library defaults
      let defaults = SwiftSnapshotConfig.libraryDefaultFormatProfile()
      #expect(profile.indentSize == defaults.indentSize)
      #expect(profile.indentStyle == defaults.indentStyle)
      #expect(profile.endOfLine == defaults.endOfLine)
      #expect(profile.insertFinalNewline == defaults.insertFinalNewline)
      #expect(profile.trimTrailingWhitespace == defaults.trimTrailingWhitespace)
    }
    
    /// Test that snapshot export with missing .swift-format file still generates files
    @Test func snapshotExportWithMissingConfigFile() throws {
      let tempDir = FileManager.default.temporaryDirectory
      let configURL = tempDir.appendingPathComponent("nonexistent-\(UUID()).swift-format")
      
      // Ensure file doesn't exist
      #expect(!FileManager.default.fileExists(atPath: configURL.path))
      
      // Set the config source to the missing file
      SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(configURL))
      defer { SwiftSnapshotConfig.resetToLibraryDefaults() }
      
      // Try to generate Swift code - should not throw
      struct TestStruct {
        let value: Int
      }
      
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: TestStruct(value: 42),
        variableName: "test"
      )
      
      // Verify code was generated
      #expect(code.contains("extension TestStruct"))
      #expect(code.contains("static let test"))
    }
    
    /// Test loading profile with nil source returns defaults
    @Test func loadProfileWithNilSource() throws {
      let profile = try FormatConfigLoader.loadProfile(from: nil)
      
      // Should return library defaults
      let defaults = SwiftSnapshotConfig.libraryDefaultFormatProfile()
      #expect(profile.indentSize == defaults.indentSize)
      #expect(profile.indentStyle == defaults.indentStyle)
      #expect(profile.endOfLine == defaults.endOfLine)
      #expect(profile.insertFinalNewline == defaults.insertFinalNewline)
      #expect(profile.trimTrailingWhitespace == defaults.trimTrailingWhitespace)
    }
  }
}
