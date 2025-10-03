import Foundation

/// Resolves output paths for snapshot files
///
/// `PathResolver` implements the directory and file name resolution logic for snapshot exports.
/// It provides a predictable, deterministic strategy with multiple override layers.
///
/// ## Resolution Priority
///
/// Directory resolution follows this precedence (highest to lowest):
/// 1. `outputBasePath` parameter from ``SwiftSnapshotRuntime/export(instance:variableName:fileName:outputBasePath:allowOverwrite:header:context:testName:line:fileID:filePath:)``
/// 2. ``SwiftSnapshotConfig/setGlobalRoot(_:)``
/// 3. `SWIFT_SNAPSHOT_ROOT` environment variable
/// 4. Default: `__Snapshots__` subdirectory adjacent to calling file
///
/// ## File Naming
///
/// Generated files follow the pattern: `TypeName+variableName.swift`
///
/// Custom names can be specified via the `fileName` parameter.
///
/// ## Example
///
/// ```swift
/// // Default resolution (creates __Snapshots__ next to current file)
/// let url = try SwiftSnapshotRuntime.export(
///     instance: user,
///     variableName: "testUser"
/// )
/// // Output: ./MyTests/__Snapshots__/User+testUser.swift
///
/// // With custom directory
/// let url2 = try SwiftSnapshotRuntime.export(
///     instance: user,
///     variableName: "adminUser",
///     outputBasePath: "/path/to/fixtures"
/// )
/// // Output: /path/to/fixtures/User+adminUser.swift
/// ```
///
/// ## See Also
/// - ``SwiftSnapshotConfig`` for global directory configuration
/// - ``SwiftSnapshotRuntime`` for the main export API
enum PathResolver {
  /// Resolve the output directory for a snapshot
  ///
  /// Determines where snapshot files should be written based on configuration priority.
  ///
  /// ## Resolution Strategy
  ///
  /// 1. **Explicit path**: If `outputBasePath` is provided, use it directly
  /// 2. **Global config**: Check ``SwiftSnapshotConfig/getGlobalRoot()``
  /// 3. **Environment**: Check `SWIFT_SNAPSHOT_ROOT` environment variable
  /// 4. **Default**: Create `__Snapshots__` adjacent to the calling file
  ///
  /// - Parameters:
  ///   - outputBasePath: Optional explicit directory path (highest priority)
  ///   - fileID: Source file identifier (from `#fileID`)
  ///   - filePath: Source file path (from `#filePath`)
  ///
  /// - Returns: URL to the output directory where snapshot files should be written
  static func resolveOutputDirectory(
    outputBasePath: String?,
    fileID: StaticString,
    filePath: StaticString
  ) -> URL {
    // 1. Explicit outputBasePath
    if let basePath = outputBasePath {
      return URL(fileURLWithPath: basePath)
    }

    // 2. Global configuration
    if let globalRoot = SwiftSnapshotConfig.getGlobalRoot() {
      return globalRoot
    }

    // 3. Environment variable
    if let envRoot = ProcessInfo.processInfo.environment["SWIFT_SNAPSHOT_ROOT"] {
      return URL(fileURLWithPath: envRoot)
    }

    // 4. Default based on file location
    let filePathStr = "\(filePath)"
    let fileURL = URL(fileURLWithPath: filePathStr)
    let directory = fileURL.deletingLastPathComponent()

    return directory.appendingPathComponent("__Snapshots__")
  }

  /// Resolve the full file path for a snapshot
  ///
  /// Constructs the complete file path including directory and filename.
  ///
  /// ## File Naming Strategy
  ///
  /// - **With custom fileName**: Uses the provided name (appends `.swift` if missing)
  /// - **Default**: Uses pattern `TypeName+variableName.swift`
  ///
  /// ## Example
  ///
  /// ```swift
  /// // Default naming
  /// resolveFilePath(
  ///     typeName: "User",
  ///     variableName: "testUser",
  ///     fileName: nil,
  ///     outputDirectory: URL(fileURLWithPath: "/fixtures")
  /// )
  /// // Returns: /fixtures/User+testUser.swift
  ///
  /// // Custom naming
  /// resolveFilePath(
  ///     typeName: "User",
  ///     variableName: "testUser",
  ///     fileName: "UserFixtures",
  ///     outputDirectory: URL(fileURLWithPath: "/fixtures")
  /// )
  /// // Returns: /fixtures/UserFixtures.swift
  /// ```
  ///
  /// - Parameters:
  ///   - typeName: Name of the type being exported
  ///   - variableName: Name of the variable (used in default file naming)
  ///   - fileName: Optional custom file name (with or without `.swift` extension)
  ///   - outputDirectory: Directory where the file will be created
  ///
  /// - Returns: Complete URL to the snapshot file
  static func resolveFilePath(
    typeName: String,
    variableName: String,
    fileName: String?,
    outputDirectory: URL
  ) -> URL {
    let finalFileName: String
    if let fileName = fileName {
      finalFileName = fileName.hasSuffix(".swift") ? fileName : "\(fileName).swift"
    } else {
      // Default: TypeName+VariableName.swift
      finalFileName = "\(typeName)+\(variableName).swift"
    }

    return outputDirectory.appendingPathComponent(finalFileName)
  }
}
