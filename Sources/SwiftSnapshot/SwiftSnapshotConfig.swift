import Foundation

/// Source for format configuration
public enum FormatConfigSource {
    /// Use .editorconfig file
    case editorconfig(URL)
    /// Use .swift-format file
    case swiftFormat(URL)
}

/// Global configuration for SwiftSnapshot
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
    
    /// Set the format configuration source (either .editorconfig or .swift-format)
    public static func setFormatConfigSource(_ source: FormatConfigSource?) {
        lock.lock()
        defer { lock.unlock() }
        formatConfigSource = source
    }
    
    /// Get the current format configuration source
    public static func getFormatConfigSource() -> FormatConfigSource? {
        lock.lock()
        defer { lock.unlock() }
        return formatConfigSource
    }
}
