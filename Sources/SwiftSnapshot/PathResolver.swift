import Foundation

/// Resolves output paths for snapshot files
enum PathResolver {
    /// Resolve the output directory for a snapshot
    /// Priority:
    /// 1. outputBasePath argument
    /// 2. SwiftSnapshotConfig.getGlobalRoot()
    /// 3. SWIFT_SNAPSHOT_ROOT environment variable
    /// 4. Default: __Snapshots__ adjacent to test file if in Tests/, else temp directory
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
