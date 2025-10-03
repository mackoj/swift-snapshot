import Dependencies
import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshot

extension SnapshotTests {
  @Suite struct DependencyInjectionTests {
    init() {
      // Reset to library defaults before each test
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - SwiftSnapshotConfigClient Tests

    /// Test that the live client correctly wraps static methods
    @Test func liveClientWrapsStaticMethods() throws {
      let client = SwiftSnapshotConfigClient.live

      // Test root directory
      let testRoot = URL(fileURLWithPath: "/tmp/test-root")
      client.setGlobalRoot(testRoot)
      #expect(client.getGlobalRoot()?.path == testRoot.path)
      #expect(SwiftSnapshotConfig.getGlobalRoot()?.path == testRoot.path)

      // Test header
      let testHeader = "// Test Header"
      client.setGlobalHeader(testHeader)
      #expect(client.getGlobalHeader() == testHeader)
      #expect(SwiftSnapshotConfig.getGlobalHeader() == testHeader)

      // Clean up
      client.setGlobalRoot(nil)
      client.setGlobalHeader(nil)
    }

    /// Test that baseline defaults are stable
    @Test func libraryDefaultsStableViaClient() throws {
      let client = SwiftSnapshotConfigClient.live

      let renderOpts = client.libraryDefaultRenderOptions()
      #expect(renderOpts.sortDictionaryKeys == true)
      #expect(renderOpts.setDeterminism == true)
      #expect(renderOpts.dataInlineThreshold == 16)
      #expect(renderOpts.forceEnumDotSyntax == true)

      let formatProfile = client.libraryDefaultFormatProfile()
      #expect(formatProfile.indentStyle == .space)
      #expect(formatProfile.indentSize == 4)
      #expect(formatProfile.endOfLine == .lf)
      #expect(formatProfile.insertFinalNewline == true)
      #expect(formatProfile.trimTrailingWhitespace == true)
    }

    /// Test that resetToLibraryDefaults restores baseline values
    @Test func resetViaClientRestoresBaseline() throws {
      let client = SwiftSnapshotConfigClient.live

      // Modify configuration
      client.setGlobalRoot(URL(fileURLWithPath: "/custom/path"))
      client.setGlobalHeader("Custom Header")
      
      let customRenderOpts = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: false,
        dataInlineThreshold: 32,
        forceEnumDotSyntax: false
      )
      client.setRenderOptions(customRenderOpts)
      
      let customProfile = FormatProfile(
        indentStyle: .tab,
        indentSize: 2,
        endOfLine: .crlf,
        insertFinalNewline: false,
        trimTrailingWhitespace: false
      )
      client.setFormatProfile(customProfile)

      // Verify customization
      #expect(client.getGlobalRoot() != nil)
      #expect(client.getGlobalHeader() != nil)
      #expect(client.getRenderOptions().sortDictionaryKeys == false)
      #expect(client.getFormatProfile().indentSize == 2)

      // Reset to defaults
      client.resetToLibraryDefaults()

      // Verify restoration
      #expect(client.getGlobalRoot() == nil)
      #expect(client.getGlobalHeader() == nil)
      
      let restoredRenderOpts = client.getRenderOptions()
      #expect(restoredRenderOpts.sortDictionaryKeys == true)
      #expect(restoredRenderOpts.setDeterminism == true)
      #expect(restoredRenderOpts.dataInlineThreshold == 16)
      #expect(restoredRenderOpts.forceEnumDotSyntax == true)
      
      let restoredProfile = client.getFormatProfile()
      #expect(restoredProfile.indentStyle == .space)
      #expect(restoredProfile.indentSize == 4)
      #expect(restoredProfile.endOfLine == .lf)
      #expect(restoredProfile.insertFinalNewline == true)
      #expect(restoredProfile.trimTrailingWhitespace == true)
    }

    /// Test dependency injection with override
    @Test func overridePropagatesThroughClient() throws {
      let testRoot = URL(fileURLWithPath: "/tmp/test-root")
      let testHeader = "// Test Header"
      
      // Create a test client with custom values
      let testClient = SwiftSnapshotConfigClient(
        getGlobalRoot: { testRoot },
        setGlobalRoot: { _ in },
        getGlobalHeader: { testHeader },
        setGlobalHeader: { _ in },
        getFormatConfigSource: { nil },
        setFormatConfigSource: { _ in },
        getRenderOptions: { 
          RenderOptions(
            sortDictionaryKeys: false,
            setDeterminism: false,
            dataInlineThreshold: 8,
            forceEnumDotSyntax: false
          )
        },
        setRenderOptions: { _ in },
        getFormatProfile: {
          FormatProfile(
            indentStyle: .space,
            indentSize: 2,
            endOfLine: .lf,
            insertFinalNewline: false,
            trimTrailingWhitespace: false
          )
        },
        setFormatProfile: { _ in },
        resetToLibraryDefaults: { },
        libraryDefaultRenderOptions: { 
          RenderOptions(
            sortDictionaryKeys: true,
            setDeterminism: true,
            dataInlineThreshold: 16,
            forceEnumDotSyntax: true
          )
        },
        libraryDefaultFormatProfile: {
          FormatProfile(
            indentStyle: .space,
            indentSize: 4,
            endOfLine: .lf,
            insertFinalNewline: true,
            trimTrailingWhitespace: true
          )
        }
      )

      // Test the override
      try withDependencies {
        $0.swiftSnapshotConfig = testClient
      } operation: {
        @Dependency(\.swiftSnapshotConfig) var config
        
        #expect(config.getGlobalRoot()?.path == testRoot.path)
        #expect(config.getGlobalHeader() == testHeader)
        #expect(config.getRenderOptions().sortDictionaryKeys == false)
        #expect(config.getFormatProfile().indentSize == 2)
      }
    }

    /// Test convenience methods
    @Test func convenienceMethodsWork() throws {
      let client = SwiftSnapshotConfigClient.live
      
      let renderOpts = client.makeRenderOptions()
      let formatProfile = client.makeFormatProfile()
      
      #expect(renderOpts.sortDictionaryKeys == true)
      #expect(formatProfile.indentSize == 4)
    }

    /// Test that dependency injection works in SwiftSnapshotRuntime
    @Test func dependencyInjectionInRuntime() throws {
      // Create a test with custom configuration
      let testClient = SwiftSnapshotConfigClient(
        getGlobalRoot: { nil },
        setGlobalRoot: { _ in },
        getGlobalHeader: { "// Custom Test Header" },
        setGlobalHeader: { _ in },
        getFormatConfigSource: { nil },
        setFormatConfigSource: { _ in },
        getRenderOptions: { 
          RenderOptions(
            sortDictionaryKeys: true,
            setDeterminism: true,
            dataInlineThreshold: 16,
            forceEnumDotSyntax: true
          )
        },
        setRenderOptions: { _ in },
        getFormatProfile: {
          FormatProfile(
            indentStyle: .space,
            indentSize: 2,
            endOfLine: .lf,
            insertFinalNewline: true,
            trimTrailingWhitespace: true
          )
        },
        setFormatProfile: { _ in },
        resetToLibraryDefaults: { },
        libraryDefaultRenderOptions: { 
          RenderOptions(
            sortDictionaryKeys: true,
            setDeterminism: true,
            dataInlineThreshold: 16,
            forceEnumDotSyntax: true
          )
        },
        libraryDefaultFormatProfile: {
          FormatProfile(
            indentStyle: .space,
            indentSize: 4,
            endOfLine: .lf,
            insertFinalNewline: true,
            trimTrailingWhitespace: true
          )
        }
      )

      try withDependencies {
        $0.swiftSnapshotConfig = testClient
      } operation: {
        let code = try SwiftSnapshotRuntime.generateSwiftCode(
          instance: 42,
          variableName: "testValue"
        )

        // Verify that custom header is used
        #expect(code.contains("// Custom Test Header"))
        
        // Verify that the code was generated successfully
        #expect(code.contains("static let testValue"))
        #expect(code.contains("Int = 42"))
      }
    }

    /// Test that static API still works during transition period
    @Test func staticAPIStillWorks() throws {
      // This verifies backward compatibility
      SwiftSnapshotConfig.setGlobalHeader("// Static API Header")
      let header = SwiftSnapshotConfig.getGlobalHeader()
      #expect(header == "// Static API Header")

      let renderOpts = RenderOptions(
        sortDictionaryKeys: false,
        setDeterminism: true,
        dataInlineThreshold: 32,
        forceEnumDotSyntax: false
      )
      SwiftSnapshotConfig.setRenderOptions(renderOpts)
      let retrieved = SwiftSnapshotConfig.renderOptions()
      #expect(retrieved.sortDictionaryKeys == false)
      #expect(retrieved.dataInlineThreshold == 32)

      // Clean up
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    /// Test baseline constants match library defaults
    @Test func defaultsStaticHelpersMatchClient() throws {
      let client = SwiftSnapshotConfigClient.live
      
      // Reset to ensure we're at baseline
      SwiftSnapshotConfig.resetToLibraryDefaults()
      
      // Static API defaults should match client defaults
      let staticRenderOpts = SwiftSnapshotConfig.renderOptions()
      let clientRenderOpts = client.libraryDefaultRenderOptions()
      
      #expect(staticRenderOpts.sortDictionaryKeys == clientRenderOpts.sortDictionaryKeys)
      #expect(staticRenderOpts.setDeterminism == clientRenderOpts.setDeterminism)
      #expect(staticRenderOpts.dataInlineThreshold == clientRenderOpts.dataInlineThreshold)
      #expect(staticRenderOpts.forceEnumDotSyntax == clientRenderOpts.forceEnumDotSyntax)
      
      let staticProfile = SwiftSnapshotConfig.formattingProfile()
      let clientProfile = client.libraryDefaultFormatProfile()
      
      #expect(staticProfile.indentStyle == clientProfile.indentStyle)
      #expect(staticProfile.indentSize == clientProfile.indentSize)
      #expect(staticProfile.endOfLine == clientProfile.endOfLine)
      #expect(staticProfile.insertFinalNewline == clientProfile.insertFinalNewline)
      #expect(staticProfile.trimTrailingWhitespace == clientProfile.trimTrailingWhitespace)
    }
  }
}
