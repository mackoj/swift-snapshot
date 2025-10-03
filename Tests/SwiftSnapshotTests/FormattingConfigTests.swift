import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshot

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
  }
}
