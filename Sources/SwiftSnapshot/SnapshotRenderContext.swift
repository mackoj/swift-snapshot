import Foundation

/// Context provided to custom renderers
public struct SnapshotRenderContext {
    /// Breadcrumb path within the object graph
    public let path: [String]
    
    /// Formatting profile to use
    public let formatting: FormatProfile
    
    /// Render options
    public let options: RenderOptions
    
    public init(
        path: [String] = [],
        formatting: FormatProfile = FormatProfile(),
        options: RenderOptions = RenderOptions()
    ) {
        self.path = path
        self.formatting = formatting
        self.options = options
    }
    
    /// Create a new context with an additional path component
    func appending(path component: String) -> SnapshotRenderContext {
        SnapshotRenderContext(
            path: path + [component],
            formatting: formatting,
            options: options
        )
    }
}
