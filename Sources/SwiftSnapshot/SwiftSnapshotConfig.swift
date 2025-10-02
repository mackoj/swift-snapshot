import Foundation

/// Source for format configuration.
///
/// Specifies which configuration file to use for code formatting.
/// Choose either `.editorconfig` or `.swift-format`, not both.
///
/// Example:
/// ```swift
/// // Use .editorconfig
/// let configURL = URL(fileURLWithPath: ".editorconfig")
/// SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
///
/// // Or use .swift-format
/// let formatURL = URL(fileURLWithPath: ".swift-format")
/// SwiftSnapshotConfig.setFormatConfigSource(.swiftFormat(formatURL))
/// ```
public enum FormatConfigSource {
  /// Use .editorconfig file for formatting configuration
  case editorconfig(URL)
  /// Use .swift-format JSON file for formatting configuration
  case swiftFormat(URL)
}

/// Global configuration for SwiftSnapshot.
///
/// Provides static methods to configure snapshot generation behavior including:
/// - Output directory paths
/// - Global headers for generated files
/// - Code formatting profiles
/// - Format configuration sources (.editorconfig or .swift-format)
/// - Rendering options
///
/// All configuration methods are thread-safe.
///
/// Example:
/// ```swift
/// // Configure global settings
/// SwiftSnapshotConfig.setGlobalRoot(URL(fileURLWithPath: "./Fixtures"))
/// SwiftSnapshotConfig.setGlobalHeader("// Auto-generated fixtures")
///
/// // Configure formatting from .editorconfig
/// let configURL = URL(fileURLWithPath: ".editorconfig")
/// SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
/// ```
public enum SwiftSnapshotConfig {
  private static var globalRoot: URL?
  private static var globalHeader: String?
  private static var formatProfile: FormatProfile = FormatProfile()
  private static var formatConfigSource: FormatConfigSource?
  private static var renderOpts: RenderOptions = RenderOptions()
  private static let lock = NSLock()

  /// Set the global root directory for snapshot output
  public static func setGlobalRoot(_ url: URL?) {
    lock.lock()
    defer { lock.unlock() }
    globalRoot = url
  }

  /// Get the global root directory
  public static func getGlobalRoot() -> URL? {
    lock.lock()
    defer { lock.unlock() }
    return globalRoot
  }

  /// Set the global header to be inserted at the top of generated files
  public static func setGlobalHeader(_ header: String?) {
    lock.lock()
    defer { lock.unlock() }
    globalHeader = header
  }

  /// Get the global header
  public static func getGlobalHeader() -> String? {
    lock.lock()
    defer { lock.unlock() }
    return globalHeader
  }

  /// Set the formatting profile
  public static func setFormattingProfile(_ profile: FormatProfile) {
    lock.lock()
    defer { lock.unlock() }
    formatProfile = profile
  }

  /// Get the current formatting profile
  public static func formattingProfile() -> FormatProfile {
    lock.lock()
    defer { lock.unlock() }
    return formatProfile
  }

  /// Set the render options
  public static func setRenderOptions(_ options: RenderOptions) {
    lock.lock()
    defer { lock.unlock() }
    renderOpts = options
  }

  /// Get the current render options
  public static func renderOptions() -> RenderOptions {
    lock.lock()
    defer { lock.unlock() }
    return renderOpts
  }

  /// Set the format configuration source (either .editorconfig or .swift-format).
  ///
  /// Use this to specify which configuration file should be used for formatting.
  /// Pass `nil` to use default formatting.
  ///
  /// - Parameter source: The format configuration source, or `nil` for defaults
  ///
  /// Example:
  /// ```swift
  /// let configURL = URL(fileURLWithPath: ".editorconfig")
  /// SwiftSnapshotConfig.setFormatConfigSource(.editorconfig(configURL))
  /// ```
  public static func setFormatConfigSource(_ source: FormatConfigSource?) {
    lock.lock()
    defer { lock.unlock() }
    formatConfigSource = source
  }

  /// Get the current format configuration source.
  ///
  /// Returns the currently configured format source, or `nil` if using defaults.
  ///
  /// - Returns: The format configuration source, or `nil` if none is set
  public static func getFormatConfigSource() -> FormatConfigSource? {
    lock.lock()
    defer { lock.unlock() }
    return formatConfigSource
  }
}
