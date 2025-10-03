import Foundation
import IssueReporting
import SwiftSyntax
import Dependencies

/// Main runtime API for SwiftSnapshot
///
/// **Note**: All public methods are only available in DEBUG builds.
/// In release builds, they become no-ops to ensure zero runtime overhead in production.
public enum SwiftSnapshotRuntime {
  /// Export a value as a Swift source file
  ///
  /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
  /// it returns a placeholder URL and performs no file I/O.
  @discardableResult
  public static func export<T>(
    instance: T,
    variableName: String,
    fileName: String? = nil,
    outputBasePath: String? = nil,
    allowOverwrite: Bool = true,
    header: String? = nil,
    context: String? = nil,
    testName: String? = nil,
    line: UInt = #line,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath
  ) throws -> URL {
    #if DEBUG
    // Sanitize the variable name to ensure it's a valid Swift identifier
    let sanitizedVariableName = sanitizeVariableName(variableName)
    
    // Generate the Swift code
    let code = try generateSwiftCode(
      instance: instance,
      variableName: sanitizedVariableName,
      header: header,
      context: context
    )

    // Resolve output directory
    let outputDirectory = PathResolver.resolveOutputDirectory(
      outputBasePath: outputBasePath,
      fileID: fileID,
      filePath: filePath
    )

    // Resolve full file path
    let typeName = String(describing: T.self)
    let filePath = PathResolver.resolveFilePath(
      typeName: typeName,
      variableName: sanitizedVariableName,
      fileName: fileName,
      outputDirectory: outputDirectory
    )

    // Check if file exists and overwrite is disallowed
    if !allowOverwrite && FileManager.default.fileExists(atPath: filePath.path) {
      throw SwiftSnapshotError.overwriteDisallowed(filePath)
    }

    // Create directory if needed
    let directory = filePath.deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      throw SwiftSnapshotError.io("Failed to create directory: \(error.localizedDescription)")
    }

    // Write file
    do {
      try code.write(to: filePath, atomically: true, encoding: .utf8)
    } catch {
      throw SwiftSnapshotError.io("Failed to write file: \(error.localizedDescription)")
    }

    return filePath
    #else
    // In non-DEBUG builds, return a placeholder URL without performing any I/O
    reportIssue("SwiftSnapshot.export() called in release build. This method should only be used in DEBUG builds.")
    return URL(fileURLWithPath: "/tmp/swift-snapshot-noop")
    #endif
  }

  /// Generate Swift code for a value without writing to disk
  internal static func generateSwiftCode<T>(
    instance: T,
    variableName: String,
    header: String? = nil,
    context: String? = nil
  ) throws -> String {
    @Dependency(\.swiftSnapshotConfig) var snapshotConfig
    
    // Sanitize the variable name to ensure it's a valid Swift identifier
    let sanitizedVariableName = sanitizeVariableName(variableName)
    
    // Get formatting and render options
    // If a config source is set, load the profile from it; otherwise use the stored profile
    let formatting: FormatProfile
    if let configSource = snapshotConfig.getFormatConfigSource() {
      formatting = try FormatConfigLoader.loadProfile(from: configSource)
    } else {
      formatting = snapshotConfig.getFormatProfile()
    }
    let options = snapshotConfig.getRenderOptions()

    // Determine header to use
    let effectiveHeader = header ?? snapshotConfig.getGlobalHeader()

    // Create render context
    let renderContext = SnapshotRenderContext(
      path: [],
      formatting: formatting,
      options: options
    )

    // Render the value
    let expression: ExprSyntax
    do {
      expression = try ValueRenderer.render(instance, context: renderContext)
    } catch let error as SwiftSnapshotError {
      // Re-throw with better context using IssueReporting
      reportIssue("Failed to render value: \(error.description)")
      throw error
    } catch {
      reportIssue("Unexpected error rendering value: \(error)")
      throw SwiftSnapshotError.reflection(
        "Unexpected error: \(error.localizedDescription)",
        path: []
      )
    }

    // Get type name
    let typeName = String(describing: T.self)

    // Format the file
    let code = CodeFormatter.formatFile(
      typeName: typeName,
      variableName: sanitizedVariableName,
      expression: expression,
      header: effectiveHeader,
      context: context,
      profile: formatting
    )

    return code
  }
  
  /// Sanitize a variable name to ensure it's a valid Swift identifier
  ///
  /// This function:
  /// - Replaces invalid characters with underscores
  /// - Ensures the name starts with a letter or underscore (prefixes with _ if needed)
  /// - Wraps Swift keywords in backticks
  /// - Returns a fallback "_" for empty or all-invalid names
  ///
  /// - Parameter name: The variable name to sanitize
  /// - Returns: A valid Swift identifier
  private static func sanitizeVariableName(_ name: String) -> String {
    // Define Swift keywords that need to be escaped
    let swiftKeywords: Set<String> = [
      "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func",
      "import", "init", "inout", "internal", "let", "open", "operator", "private",
      "precedencegroup", "protocol", "public", "rethrows", "static", "struct",
      "subscript", "typealias", "var", "break", "case", "catch", "continue", "default",
      "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat",
      "return", "throw", "switch", "where", "while", "as", "false", "is", "nil",
      "self", "Self", "super", "throws", "true", "try", "await", "async"
    ]
    
    // If the name is a Swift keyword, wrap it in backticks
    if swiftKeywords.contains(name) {
      return "`\(name)`"
    }
    
    // Replace invalid characters with underscores
    let sanitized = name.map { char -> Character in
      if char.isLetter || char.isNumber || char == "_" {
        return char
      } else {
        return "_"
      }
    }
    
    var result = String(sanitized)
    
    // If empty or only underscores, return single underscore
    if result.isEmpty || result.allSatisfy({ $0 == "_" }) {
      return "_"
    }
    
    // Ensure the name starts with a letter or underscore
    if let first = result.first, first.isNumber {
      result = "_" + result
    }
    
    return result
  }
}
