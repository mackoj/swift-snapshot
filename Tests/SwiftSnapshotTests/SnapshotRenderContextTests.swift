import Testing
import Foundation
import Dependencies

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for SnapshotRenderContext
  @Suite struct SnapshotRenderContextTests {
    
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    // MARK: - Initialization Tests
    
    /// Test default initialization
    @Test func defaultInitialization() {
      let context = SnapshotRenderContext()
      
      #expect(context.path.isEmpty)
      // formatting and options should use defaults from config
      #expect(context.formatting.indentSize == 4)
      #expect(context.options.sortDictionaryKeys == true)
    }
    
    /// Test initialization with custom path
    @Test func initializationWithPath() {
      let context = SnapshotRenderContext(path: ["root", "field"])
      
      #expect(context.path == ["root", "field"])
    }
    
    /// Test initialization with custom formatting
    @Test func initializationWithFormatting() {
      let customFormatting = FormatProfile(
        indentStyle: .tab,
        indentSize: 2,
        endOfLine: .crlf,
        insertFinalNewline: false,
        trimTrailingWhitespace: false
      )
      
      let context = SnapshotRenderContext(formatting: customFormatting)
      
      #expect(context.formatting.indentStyle == .tab)
      #expect(context.formatting.indentSize == 2)
      #expect(context.formatting.endOfLine == .crlf)
    }
    
    /// Test initialization with custom options
    @Test func initializationWithOptions() {
      let customOptions = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 256,
        forceEnumDotSyntax: false
      )
      
      let context = SnapshotRenderContext(options: customOptions)
      
      #expect(context.options.sortDictionaryKeys == false)
      #expect(context.options.setDeterminism == false)
      #expect(context.options.dataInlineThreshold == 256)
      #expect(context.options.forceEnumDotSyntax == false)
    }
    
    /// Test initialization with all custom parameters
    @Test func initializationWithAllParameters() {
      let customFormatting = FormatProfile(
        indentStyle: .space,
        indentSize: 8,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      let customOptions = RenderOptions(
        sortDictionaryKeys: true,
        setDeterminism: true,
        dataInlineThreshold: 64,
        forceEnumDotSyntax: true
      )
      
      let context = SnapshotRenderContext(
        path: ["root", "nested"],
        formatting: customFormatting,
        options: customOptions
      )
      
      #expect(context.path == ["root", "nested"])
      #expect(context.formatting.indentSize == 8)
      #expect(context.options.dataInlineThreshold == 64)
    }
    
    // MARK: - Path Appending Tests
    
    /// Test appending single path component
    @Test func appendingSinglePathComponent() {
      let context = SnapshotRenderContext(path: ["root"])
      let newContext = context.appending(path: "field")
      
      #expect(newContext.path == ["root", "field"])
      // Original context should remain unchanged
      #expect(context.path == ["root"])
    }
    
    /// Test appending to empty path
    @Test func appendingToEmptyPath() {
      let context = SnapshotRenderContext()
      let newContext = context.appending(path: "first")
      
      #expect(newContext.path == ["first"])
    }
    
    /// Test multiple sequential appends
    @Test func multipleSequentialAppends() {
      let context = SnapshotRenderContext()
      let context1 = context.appending(path: "level1")
      let context2 = context1.appending(path: "level2")
      let context3 = context2.appending(path: "level3")
      
      #expect(context.path.isEmpty)
      #expect(context1.path == ["level1"])
      #expect(context2.path == ["level1", "level2"])
      #expect(context3.path == ["level1", "level2", "level3"])
    }
    
    /// Test that appending preserves formatting and options
    @Test func appendingPreservesProperties() {
      let customFormatting = FormatProfile(
        indentStyle: .tab,
        indentSize: 2,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      let customOptions = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 128,
        forceEnumDotSyntax: false
      )
      
      let context = SnapshotRenderContext(
        path: ["root"],
        formatting: customFormatting,
        options: customOptions
      )
      
      let newContext = context.appending(path: "field")
      
      #expect(newContext.formatting.indentStyle == .tab)
      #expect(newContext.formatting.indentSize == 2)
      #expect(newContext.options.sortDictionaryKeys == false)
      #expect(newContext.options.dataInlineThreshold == 128)
    }
    
    // MARK: - Dependency Injection Tests
    
    /// Test that context uses config from dependency injection
    @Test func usesConfigFromDependencies() throws {
      let customProfile = FormatProfile(
        indentStyle: .space,
        indentSize: 3,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      let customOptions = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: true,
        dataInlineThreshold: 99,
        forceEnumDotSyntax: true
      )
      
      SwiftSnapshotConfig.setFormattingProfile(customProfile)
      SwiftSnapshotConfig.setRenderOptions(customOptions)
      
      // Context without explicit formatting/options should use config
      let context = SnapshotRenderContext()
      
      #expect(context.formatting.indentSize == 3)
      #expect(context.options.dataInlineThreshold == 99)
      
      // Cleanup
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }
    
    /// Test path with special characters
    @Test func pathWithSpecialCharacters() {
      let context = SnapshotRenderContext(path: ["root"])
      let newContext = context
        .appending(path: "array[0]")
        .appending(path: "dict[\"key\"]")
        .appending(path: "field.nested")
      
      #expect(newContext.path == ["root", "array[0]", "dict[\"key\"]", "field.nested"])
    }
  }
}
