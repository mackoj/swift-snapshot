import Testing
import Foundation

@testable import SwiftSnapshot

extension SnapshotTests {
  /// Tests for RenderOptions and FormatProfile
  @Suite struct RenderOptionsTests {
    
    // MARK: - RenderOptions Tests
    
    /// Test RenderOptions initialization with all properties
    @Test func renderOptionsInitialization() {
      let options = RenderOptions(
        sortDictionaryKeys: true,
        setDeterminism: false,
        dataInlineThreshold: 128,
        forceEnumDotSyntax: true
      )
      
      #expect(options.sortDictionaryKeys == true)
      #expect(options.setDeterminism == false)
      #expect(options.dataInlineThreshold == 128)
      #expect(options.forceEnumDotSyntax == true)
    }
    
    /// Test RenderOptions with default-like values
    @Test func renderOptionsDefaults() {
      let options = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 0,
        forceEnumDotSyntax: false
      )
      
      #expect(options.sortDictionaryKeys == false)
      #expect(options.setDeterminism == false)
      #expect(options.dataInlineThreshold == 0)
      #expect(options.forceEnumDotSyntax == false)
    }
    
    /// Test RenderOptions property mutation
    @Test func renderOptionsMutation() {
      var options = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 16,
        forceEnumDotSyntax: false
      )
      
      options.sortDictionaryKeys = true
      options.setDeterminism = true
      options.dataInlineThreshold = 32
      options.forceEnumDotSyntax = true
      
      #expect(options.sortDictionaryKeys == true)
      #expect(options.setDeterminism == true)
      #expect(options.dataInlineThreshold == 32)
      #expect(options.forceEnumDotSyntax == true)
    }
    
    // MARK: - FormatProfile Tests
    
    /// Test FormatProfile initialization with all properties
    @Test func formatProfileInitialization() {
      let profile = FormatProfile(
        indentStyle: .space,
        indentSize: 2,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: false
      )
      
      #expect(profile.indentStyle == .space)
      #expect(profile.indentSize == 2)
      #expect(profile.endOfLine == .lf)
      #expect(profile.insertFinalNewline == true)
      #expect(profile.trimTrailingWhitespace == false)
    }
    
    /// Test FormatProfile with tab indent style
    @Test func formatProfileWithTabs() {
      let profile = FormatProfile(
        indentStyle: .tab,
        indentSize: 4,
        endOfLine: .crlf,
        insertFinalNewline: false,
        trimTrailingWhitespace: true
      )
      
      #expect(profile.indentStyle == .tab)
      #expect(profile.indentSize == 4)
      #expect(profile.endOfLine == .crlf)
      #expect(profile.insertFinalNewline == false)
      #expect(profile.trimTrailingWhitespace == true)
    }
    
    /// Test FormatProfile.EndOfLine string conversion
    @Test func endOfLineStringConversion() {
      let lfProfile = FormatProfile(
        indentStyle: .space,
        indentSize: 4,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      #expect(lfProfile.endOfLine.string == "\n")
      
      let crlfProfile = FormatProfile(
        indentStyle: .space,
        indentSize: 4,
        endOfLine: .crlf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      #expect(crlfProfile.endOfLine.string == "\r\n")
    }
    
    /// Test FormatProfile.indent() method with different levels
    @Test func formatProfileIndentMethod() {
      let profile = FormatProfile(
        indentStyle: .space,
        indentSize: 4,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      #expect(profile.indent(level: 0) == "")
      #expect(profile.indent(level: 1) == "    ")
      #expect(profile.indent(level: 2) == "        ")
      #expect(profile.indent(level: 3) == "            ")
    }
    
    /// Test FormatProfile.indent() method with different indent sizes
    @Test func formatProfileIndentWithDifferentSizes() {
      let profile2 = FormatProfile(
        indentStyle: .space,
        indentSize: 2,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      #expect(profile2.indent(level: 1) == "  ")
      #expect(profile2.indent(level: 2) == "    ")
      #expect(profile2.indent(level: 3) == "      ")
      
      let profile8 = FormatProfile(
        indentStyle: .space,
        indentSize: 8,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      #expect(profile8.indent(level: 1) == "        ")
      #expect(profile8.indent(level: 2) == "                ")
    }
    
    /// Test FormatProfile property mutation
    @Test func formatProfileMutation() {
      var profile = FormatProfile(
        indentStyle: .space,
        indentSize: 4,
        endOfLine: .lf,
        insertFinalNewline: true,
        trimTrailingWhitespace: true
      )
      
      profile.indentStyle = .tab
      profile.indentSize = 2
      profile.endOfLine = .crlf
      profile.insertFinalNewline = false
      profile.trimTrailingWhitespace = false
      
      #expect(profile.indentStyle == .tab)
      #expect(profile.indentSize == 2)
      #expect(profile.endOfLine == .crlf)
      #expect(profile.insertFinalNewline == false)
      #expect(profile.trimTrailingWhitespace == false)
    }
    
    /// Test IndentStyle enum cases
    @Test func indentStyleCases() {
      let spaceStyle = FormatProfile.IndentStyle.space
      let tabStyle = FormatProfile.IndentStyle.tab
      
      #expect(spaceStyle == .space)
      #expect(tabStyle == .tab)
      #expect(spaceStyle != tabStyle)
    }
    
    /// Test EndOfLine enum cases
    @Test func endOfLineCases() {
      let lf = FormatProfile.EndOfLine.lf
      let crlf = FormatProfile.EndOfLine.crlf
      
      #expect(lf == .lf)
      #expect(crlf == .crlf)
      #expect(lf != crlf)
    }
  }
}
