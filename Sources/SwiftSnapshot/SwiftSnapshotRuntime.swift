import Foundation
import IssueReporting
import SwiftSyntax

/// Main runtime API for SwiftSnapshot
public enum SwiftSnapshotRuntime {
  /// Export a value as a Swift source file
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
    // Generate the Swift code
    let code = try generateSwiftCode(
      instance: instance,
      variableName: variableName,
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
      variableName: variableName,
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
  }

  /// Generate Swift code for a value without writing to disk
  public static func generateSwiftCode<T>(
    instance: T,
    variableName: String,
    header: String? = nil,
    context: String? = nil
  ) throws -> String {
    // Get formatting and render options
    let formatting = SwiftSnapshotConfig.formattingProfile()
    let options = SwiftSnapshotConfig.renderOptions()

    // Determine header to use
    let effectiveHeader = header ?? SwiftSnapshotConfig.getGlobalHeader()

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
      variableName: variableName,
      expression: expression,
      header: effectiveHeader,
      context: context,
      profile: formatting
    )

    return code
  }
}
