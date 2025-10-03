import Foundation
import Dependencies

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
  // MARK: - Baseline Library Defaults
  private static let baselineRenderOptions = RenderOptions(
    sortDictionaryKeys: true,
    setDeterminism: true,
    dataInlineThreshold: 16,
    forceEnumDotSyntax: true
  )
  
  private static let baselineFormatProfile = FormatProfile(
    indentStyle: .space,
    indentSize: 4,
    endOfLine: .lf,
    insertFinalNewline: true,
    trimTrailingWhitespace: true
  )
  
  // MARK: - Active Configuration State
  private static var globalRoot: URL?
  private static var globalHeader: String?
  private static var formatProfile: FormatProfile = baselineFormatProfile
  private static var formatConfigSource: FormatConfigSource?
  private static var renderOpts: RenderOptions = baselineRenderOptions
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
  
  /// Reset all configuration to library defaults.
  ///
  /// This clears all global settings and restores baseline values for render options
  /// and format profile.
  public static func resetToLibraryDefaults() {
    lock.lock()
    defer { lock.unlock() }
    globalRoot = nil
    globalHeader = nil
    formatProfile = baselineFormatProfile
    formatConfigSource = nil
    renderOpts = baselineRenderOptions
  }
  
  /// Get the library default render options.
  ///
  /// Returns the baseline render options that the library uses when no custom
  /// configuration is set.
  ///
  /// - Returns: The baseline render options
  public static func libraryDefaultRenderOptions() -> RenderOptions {
    return baselineRenderOptions
  }
  
  /// Get the library default format profile.
  ///
  /// Returns the baseline format profile that the library uses when no custom
  /// configuration is set.
  ///
  /// - Returns: The baseline format profile
  public static func libraryDefaultFormatProfile() -> FormatProfile {
    return baselineFormatProfile
  }
}

// MARK: - SwiftSnapshotConfigClient

/// A dependency-injectable client for SwiftSnapshot configuration.
///
/// This client provides a testable abstraction over the global configuration
/// that can be injected using swift-dependencies.
///
/// Example usage:
/// ```swift
/// @Dependency(\.swiftSnapshotConfig) var snapshotConfig
/// let opts = snapshotConfig.getRenderOptions()
/// ```
public struct SwiftSnapshotConfigClient: Sendable {
  public var getGlobalRoot: @Sendable () -> URL?
  public var setGlobalRoot: @Sendable (URL?) -> Void
  public var getGlobalHeader: @Sendable () -> String?
  public var setGlobalHeader: @Sendable (String?) -> Void
  public var getFormatConfigSource: @Sendable () -> FormatConfigSource?
  public var setFormatConfigSource: @Sendable (FormatConfigSource?) -> Void
  public var getRenderOptions: @Sendable () -> RenderOptions
  public var setRenderOptions: @Sendable (RenderOptions) -> Void
  public var getFormatProfile: @Sendable () -> FormatProfile
  public var setFormatProfile: @Sendable (FormatProfile) -> Void
  public var resetToLibraryDefaults: @Sendable () -> Void
  public var libraryDefaultRenderOptions: @Sendable () -> RenderOptions
  public var libraryDefaultFormatProfile: @Sendable () -> FormatProfile
  
  public init(
    getGlobalRoot: @escaping @Sendable () -> URL?,
    setGlobalRoot: @escaping @Sendable (URL?) -> Void,
    getGlobalHeader: @escaping @Sendable () -> String?,
    setGlobalHeader: @escaping @Sendable (String?) -> Void,
    getFormatConfigSource: @escaping @Sendable () -> FormatConfigSource?,
    setFormatConfigSource: @escaping @Sendable (FormatConfigSource?) -> Void,
    getRenderOptions: @escaping @Sendable () -> RenderOptions,
    setRenderOptions: @escaping @Sendable (RenderOptions) -> Void,
    getFormatProfile: @escaping @Sendable () -> FormatProfile,
    setFormatProfile: @escaping @Sendable (FormatProfile) -> Void,
    resetToLibraryDefaults: @escaping @Sendable () -> Void,
    libraryDefaultRenderOptions: @escaping @Sendable () -> RenderOptions,
    libraryDefaultFormatProfile: @escaping @Sendable () -> FormatProfile
  ) {
    self.getGlobalRoot = getGlobalRoot
    self.setGlobalRoot = setGlobalRoot
    self.getGlobalHeader = getGlobalHeader
    self.setGlobalHeader = setGlobalHeader
    self.getFormatConfigSource = getFormatConfigSource
    self.setFormatConfigSource = setFormatConfigSource
    self.getRenderOptions = getRenderOptions
    self.setRenderOptions = setRenderOptions
    self.getFormatProfile = getFormatProfile
    self.setFormatProfile = setFormatProfile
    self.resetToLibraryDefaults = resetToLibraryDefaults
    self.libraryDefaultRenderOptions = libraryDefaultRenderOptions
    self.libraryDefaultFormatProfile = libraryDefaultFormatProfile
  }
}

// MARK: - Live Implementation

extension SwiftSnapshotConfigClient {
  /// Live implementation backed by the existing static SwiftSnapshotConfig.
  public static let live: SwiftSnapshotConfigClient = SwiftSnapshotConfigClient(
    getGlobalRoot: { SwiftSnapshotConfig.getGlobalRoot() },
    setGlobalRoot: { SwiftSnapshotConfig.setGlobalRoot($0) },
    getGlobalHeader: { SwiftSnapshotConfig.getGlobalHeader() },
    setGlobalHeader: { SwiftSnapshotConfig.setGlobalHeader($0) },
    getFormatConfigSource: { SwiftSnapshotConfig.getFormatConfigSource() },
    setFormatConfigSource: { SwiftSnapshotConfig.setFormatConfigSource($0) },
    getRenderOptions: { SwiftSnapshotConfig.renderOptions() },
    setRenderOptions: { SwiftSnapshotConfig.setRenderOptions($0) },
    getFormatProfile: { SwiftSnapshotConfig.formattingProfile() },
    setFormatProfile: { SwiftSnapshotConfig.setFormattingProfile($0) },
    resetToLibraryDefaults: { SwiftSnapshotConfig.resetToLibraryDefaults() },
    libraryDefaultRenderOptions: { SwiftSnapshotConfig.libraryDefaultRenderOptions() },
    libraryDefaultFormatProfile: { SwiftSnapshotConfig.libraryDefaultFormatProfile() }
  )
}

// MARK: - Convenience Methods

public extension SwiftSnapshotConfigClient {
  /// Get the current render options (convenience method).
  func makeRenderOptions() -> RenderOptions { getRenderOptions() }
  
  /// Get the current format profile (convenience method).
  func makeFormatProfile() -> FormatProfile { getFormatProfile() }
}

// MARK: - Dependency Integration

private enum SwiftSnapshotConfigDependencyKey: DependencyKey {
  static let liveValue: SwiftSnapshotConfigClient = .live
  static let testValue: SwiftSnapshotConfigClient = .live
  static let previewValue: SwiftSnapshotConfigClient = .live
}

public extension DependencyValues {
  var swiftSnapshotConfig: SwiftSnapshotConfigClient {
    get { self[SwiftSnapshotConfigDependencyKey.self] }
    set { self[SwiftSnapshotConfigDependencyKey.self] = newValue }
  }
}
