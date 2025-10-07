import Foundation
import IssueReporting
import SwiftSyntax
import Dependencies

/// Main runtime API for SwiftSnapshot
///
/// `SwiftSnapshotRuntime` provides the core functionality for converting Swift values into
/// compilable Swift source code and writing them to disk. This enables creating type-safe,
/// human-readable fixtures that can be committed, diffed, and reused across your project.
///
/// ## Overview
///
/// The primary method ``export(instance:variableName:fileName:outputBasePath:allowOverwrite:header:context:testName:line:fileID:filePath:)``
/// takes any Swift value and generates a `.swift` file containing an extension with a static property.
///
/// ## Example
///
/// ```swift
/// struct User {
///     let id: Int
///     let name: String
/// }
///
/// let user = User(id: 42, name: "Alice")
/// let url = try SwiftSnapshotRuntime.export(
///     instance: user,
///     variableName: "testUser"
/// )
/// // Creates a file like: User+testUser.swift
/// // Contents:
/// // extension User {
/// //     static let testUser: User = User(id: 42, name: "Alice")
/// // }
/// ```
///
/// ## DEBUG-Only Architecture
///
/// All public methods are wrapped in `#if DEBUG` directives:
/// - **In DEBUG builds**: Full functionality with file I/O and code generation
/// - **In RELEASE builds**: Methods become no-ops, returning placeholder values
/// - **Result**: Zero runtime overhead and zero binary bloat in production
///
/// ## See Also
/// - ``SwiftSnapshotConfig`` for global configuration
/// - ``SnapshotRendererRegistry`` for custom type rendering
/// - ``SwiftSnapshotError`` for error handling
public enum SwiftSnapshotRuntime {
  /// Export a value as a Swift source file
  ///
  /// Converts any Swift value into a compilable `.swift` file containing an extension
  /// with a static property. The generated code is human-readable, type-safe, and can be
  /// committed to version control.
  ///
  /// ## Behavior
  ///
  /// 1. Sanitizes the variable name to ensure it's a valid Swift identifier
  /// 2. Renders the value using ``ValueRenderer`` (checking custom renderers first)
  /// 3. Formats the code according to ``SwiftSnapshotConfig`` settings
  /// 4. Resolves the output directory (see ``PathResolver``)
  /// 5. Creates necessary directories and writes the file
  ///
  /// ## Directory Resolution Priority
  ///
  /// The output directory is determined by the first available option:
  /// 1. `outputBasePath` parameter (highest priority)
  /// 2. ``SwiftSnapshotConfig/setGlobalRoot(_:)``
  /// 3. `SWIFT_SNAPSHOT_ROOT` environment variable
  /// 4. Default: `__Snapshots__` adjacent to the calling file
  ///
  /// ## Example
  ///
  /// ```swift
  /// let user = User(id: 1, name: "Alice")
  ///
  /// // Basic usage
  /// let url = try SwiftSnapshotRuntime.export(
  ///     instance: user,
  ///     variableName: "testUser"
  /// )
  ///
  /// // With custom header and documentation
  /// let url2 = try SwiftSnapshotRuntime.export(
  ///     instance: user,
  ///     variableName: "adminUser",
  ///     header: "// Test Fixtures - Auto-generated",
  ///     context: "Admin user fixture for authorization tests"
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - instance: The value to export. Can be any type (primitives, collections, custom types)
  ///   - variableName: Name for the generated static property. Will be sanitized to a valid Swift identifier
  ///   - fileName: Optional custom file name (without `.swift` extension). Defaults to `TypeName+variableName`
  ///   - outputBasePath: Optional directory path. Overrides global configuration
  ///   - allowOverwrite: Whether to replace existing files. Default is `true`
  ///   - header: Optional file header comment. Overrides global header from ``SwiftSnapshotConfig``
  ///   - context: Optional documentation comment for the generated property
  ///   - testName: Optional test name hint for organization (typically `#function`)
  ///   - line: Source line number (automatically captured via `#line`)
  ///   - fileID: Source file identifier (automatically captured via `#fileID`)
  ///   - filePath: Source file path (automatically captured via `#filePath`)
  ///
  /// - Returns: URL to the created `.swift` file. In release builds, returns a placeholder URL.
  ///   If an error occurs during export, it will be reported as an issue and a placeholder URL will be returned.
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
  ) -> URL {
    #if DEBUG
    return withErrorReporting(
      "Failed to export snapshot",
      fileID: fileID,
      filePath: filePath,
      line: line
    ) {
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
    } ?? URL(fileURLWithPath: "/tmp/swift-snapshot-error")
    #else
    // In non-DEBUG builds, return a placeholder URL without performing any I/O
    reportIssue("SwiftSnapshot.export() called in release build. This method should only be used in DEBUG builds.")
    return URL(fileURLWithPath: "/tmp/swift-snapshot-noop")
    #endif
  }

  /// Generate Swift code for a value without writing to disk
  ///
  /// Internal method used by ``export(instance:variableName:fileName:outputBasePath:allowOverwrite:header:context:testName:line:fileID:filePath:)``
  /// and available for testing. Converts a value to formatted Swift source code without performing file I/O.
  ///
  /// ## Process
  ///
  /// 1. Loads format configuration from ``SwiftSnapshotConfig`` or configured source
  /// 2. Creates a ``SnapshotRenderContext`` with formatting and render options
  /// 3. Renders the value using ``ValueRenderer/render(_:context:)``
  /// 4. Formats the complete file using ``CodeFormatter/formatFile(typeName:variableName:expression:header:context:profile:)``
  ///
  /// - Parameters:
  ///   - instance: The value to render
  ///   - variableName: Name for the static property
  ///   - header: Optional header comment for the file
  ///   - context: Optional documentation for the property
  ///
  /// - Returns: Formatted Swift source code as a string
  ///
  /// - Throws: ``SwiftSnapshotError`` if rendering or formatting fails
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
