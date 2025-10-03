import Testing
import Foundation

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for SwiftSnapshotConfig
  @Suite struct SwiftSnapshotConfigTests {
    
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - Global Root Tests
    
    /// Test setting and getting global root
    @Test func setAndGetGlobalRoot() {
      let testURL = URL(fileURLWithPath: "/tmp/test-snapshots")
      
      SwiftSnapshotConfig.setGlobalRoot(testURL)
      let retrieved = SwiftSnapshotConfig.getGlobalRoot()
      
      #expect(retrieved?.path == testURL.path)
      
      // Cleanup
      SwiftSnapshotConfig.setGlobalRoot(nil)
    }
    
    /// Test clearing global root
    @Test func clearGlobalRoot() {
      let testURL = URL(fileURLWithPath: "/tmp/test")
      SwiftSnapshotConfig.setGlobalRoot(testURL)
      
      SwiftSnapshotConfig.setGlobalRoot(nil)
      let retrieved = SwiftSnapshotConfig.getGlobalRoot()
      
      #expect(retrieved == nil)
    }
    
    // MARK: - Global Header Tests
    
    /// Test setting and getting global header
    @Test func setAndGetGlobalHeader() {
      let testHeader = "// This is a test header"
      
      SwiftSnapshotConfig.setGlobalHeader(testHeader)
      let retrieved = SwiftSnapshotConfig.getGlobalHeader()
      
      #expect(retrieved == testHeader)
      
      // Cleanup
      SwiftSnapshotConfig.setGlobalHeader(nil)
    }
    
    /// Test clearing global header
    @Test func clearGlobalHeader() {
      SwiftSnapshotConfig.setGlobalHeader("// Test")
      
      SwiftSnapshotConfig.setGlobalHeader(nil)
      let retrieved = SwiftSnapshotConfig.getGlobalHeader()
      
      #expect(retrieved == nil)
    }
    
    /// Test multiline global header
    @Test func multilineGlobalHeader() {
      let multilineHeader = """
        // Auto-generated file
        // Do not edit manually
        // Copyright 2024
        """
      
      SwiftSnapshotConfig.setGlobalHeader(multilineHeader)
      let retrieved = SwiftSnapshotConfig.getGlobalHeader()
      
      #expect(retrieved == multilineHeader)
      
      // Cleanup
      SwiftSnapshotConfig.setGlobalHeader(nil)
    }
    
    // MARK: - Formatting Profile Tests
    
    /// Test setting and getting formatting profile
    @Test func setAndGetFormattingProfile() {
      let customProfile = FormatProfile(
        indentStyle: .tab,
        indentSize: 8,
        endOfLine: .crlf,
        insertFinalNewline: false,
        trimTrailingWhitespace: false
      )
      
      SwiftSnapshotConfig.setFormattingProfile(customProfile)
      let retrieved = SwiftSnapshotConfig.formattingProfile()
      
      #expect(retrieved.indentStyle == .tab)
      #expect(retrieved.indentSize == 8)
      #expect(retrieved.endOfLine == .crlf)
      #expect(retrieved.insertFinalNewline == false)
      #expect(retrieved.trimTrailingWhitespace == false)
      
      // Cleanup
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - Render Options Tests
    
    /// Test setting and getting render options
    @Test func setAndGetRenderOptions() {
      let customOptions = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 256,
        forceEnumDotSyntax: false
      )
      
      SwiftSnapshotConfig.setRenderOptions(customOptions)
      let retrieved = SwiftSnapshotConfig.renderOptions()
      
      #expect(retrieved.sortDictionaryKeys == false)
      #expect(retrieved.setDeterminism == false)
      #expect(retrieved.dataInlineThreshold == 256)
      #expect(retrieved.forceEnumDotSyntax == false)
      
      // Cleanup
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - Format Config Source Tests
    
    /// Test setting and getting editorconfig source
    @Test func setAndGetEditorConfigSource() {
      let configURL = URL(fileURLWithPath: "/tmp/.editorconfig")
      
      SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
      let retrieved = SwiftSnapshotConfig.getFormatConfigSource()
      
      #expect(retrieved != nil)
      if case .editorconfig(let url) = retrieved {
        #expect(url.path == configURL.path)
      } else {
        Issue.record("Expected editorconfig source")
      }
      
      // Cleanup
      SwiftSnapshotConfig.setFormatConfigSource(nil)
    }
    
    /// Test setting and getting swift-format source
    @Test func setAndGetSwiftFormatSource() {
      let formatURL = URL(fileURLWithPath: "/tmp/.swift-format")
      
      SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(formatURL))
      let retrieved = SwiftSnapshotConfig.getFormatConfigSource()
      
      #expect(retrieved != nil)
      if case .swiftFormat(let url) = retrieved {
        #expect(url.path == formatURL.path)
      } else {
        Issue.record("Expected swiftFormat source")
      }
      
      // Cleanup
      SwiftSnapshotConfig.setFormatConfigSource(nil)
    }
    
    /// Test clearing format config source
    @Test func clearFormatConfigSource() {
      let configURL = URL(fileURLWithPath: "/tmp/.editorconfig")
      SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
      
      SwiftSnapshotConfig.setFormatConfigSource(nil)
      let retrieved = SwiftSnapshotConfig.getFormatConfigSource()
      
      #expect(retrieved == nil)
    }
    
    // MARK: - Reset Tests
    
    /// Test reset to library defaults
    @Test func resetToLibraryDefaults() {
      // Set custom values
      SwiftSnapshotConfig.setGlobalRoot(URL(fileURLWithPath: "/tmp/custom"))
      SwiftSnapshotConfig.setGlobalHeader("// Custom header")
      
      let customProfile = FormatProfile(
        indentStyle: .tab,
        indentSize: 2,
        endOfLine: .crlf,
        insertFinalNewline: false,
        trimTrailingWhitespace: false
      )
      SwiftSnapshotConfig.setFormattingProfile(customProfile)
      
      let customOptions = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 128,
        forceEnumDotSyntax: false
      )
      SwiftSnapshotConfig.setRenderOptions(customOptions)
      
      SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(URL(fileURLWithPath: "/tmp/.editorconfig")))
      
      // Reset
      SwiftSnapshotConfig.resetToLibraryDefaults()
      
      // Verify all are reset to defaults
      #expect(SwiftSnapshotConfig.getGlobalRoot() == nil)
      #expect(SwiftSnapshotConfig.getGlobalHeader() == nil)
      #expect(SwiftSnapshotConfig.getFormatConfigSource() == nil)
      
      let profile = SwiftSnapshotConfig.formattingProfile()
      #expect(profile.indentStyle == .space)
      #expect(profile.indentSize == 4)
      #expect(profile.endOfLine == .lf)
      #expect(profile.insertFinalNewline == true)
      #expect(profile.trimTrailingWhitespace == true)
      
      let options = SwiftSnapshotConfig.renderOptions()
      #expect(options.sortDictionaryKeys == true)
      #expect(options.setDeterminism == true)
      #expect(options.dataInlineThreshold == 16)
      #expect(options.forceEnumDotSyntax == true)
    }
    
    // MARK: - Library Default Methods Tests
    
    /// Test library default render options
    @Test func libraryDefaultRenderOptions() {
      let defaults = SwiftSnapshotConfig.libraryDefaultRenderOptions()
      
      #expect(defaults.sortDictionaryKeys == true)
      #expect(defaults.setDeterminism == true)
      #expect(defaults.dataInlineThreshold == 16)
      #expect(defaults.forceEnumDotSyntax == true)
    }
    
    /// Test library default format profile
    @Test func libraryDefaultFormatProfile() {
      let defaults = SwiftSnapshotConfig.libraryDefaultFormatProfile()
      
      #expect(defaults.indentStyle == .space)
      #expect(defaults.indentSize == 4)
      #expect(defaults.endOfLine == .lf)
      #expect(defaults.insertFinalNewline == true)
      #expect(defaults.trimTrailingWhitespace == true)
    }
    
    /// Test that library defaults are immutable (modifying doesn't affect subsequent calls)
    @Test func libraryDefaultsAreImmutable() {
      var defaults1 = SwiftSnapshotConfig.libraryDefaultRenderOptions()
      defaults1.sortDictionaryKeys = false
      
      let defaults2 = SwiftSnapshotConfig.libraryDefaultRenderOptions()
      #expect(defaults2.sortDictionaryKeys == true)
    }
    
    // MARK: - Thread Safety Tests
    
    /// Test that config can be accessed from multiple threads
    @Test func threadSafetyBasicTest() async {
      await withTaskGroup(of: Bool.self) { group in
        // Task 1: Set and get global root
        group.addTask {
          SwiftSnapshotConfig.setGlobalRoot(URL(fileURLWithPath: "/tmp/test1"))
          return SwiftSnapshotConfig.getGlobalRoot() != nil
        }
        
        // Task 2: Set and get global header
        group.addTask {
          SwiftSnapshotConfig.setGlobalHeader("// Header")
          return SwiftSnapshotConfig.getGlobalHeader() != nil
        }
        
        // Task 3: Set and get render options
        group.addTask {
          let opts = RenderOptions(
            sortDictionaryKeys: true,
            setDeterminism: true,
            dataInlineThreshold: 16,
            forceEnumDotSyntax: true
          )
          SwiftSnapshotConfig.setRenderOptions(opts)
          return SwiftSnapshotConfig.renderOptions().dataInlineThreshold == 16
        }
        
        // Task 4: Set and get format profile
        group.addTask {
          let profile = FormatProfile(
            indentStyle: .space,
            indentSize: 4,
            endOfLine: .lf,
            insertFinalNewline: true,
            trimTrailingWhitespace: true
          )
          SwiftSnapshotConfig.setFormattingProfile(profile)
          return SwiftSnapshotConfig.formattingProfile().indentSize == 4
        }
        
        var allSucceeded = true
        for await success in group {
          allSucceeded = allSucceeded && success
        }
        
        #expect(allSucceeded)
      }
      
      // Cleanup
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - FormatConfigSource Enum Tests
    
    /// Test FormatConfigSource enum cases
    @Test func formatConfigSourceCases() {
      let editorconfigURL = URL(fileURLWithPath: "/tmp/.editorconfig")
      let swiftFormatURL = URL(fileURLWithPath: "/tmp/.swift-format")
      
      let editorconfig = FormatConfigSource.editorconfig(editorconfigURL)
      let swiftFormat = FormatConfigSource.swiftFormat(swiftFormatURL)
      
      // Verify we can match on enum cases
      if case .editorconfig(let url) = editorconfig {
        #expect(url == editorconfigURL)
      } else {
        Issue.record("Expected editorconfig case")
      }
      
      if case .swiftFormat(let url) = swiftFormat {
        #expect(url == swiftFormatURL)
      } else {
        Issue.record("Expected swiftFormat case")
      }
    }
  }
}
