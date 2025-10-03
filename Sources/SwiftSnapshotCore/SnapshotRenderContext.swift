import Foundation
import Dependencies

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
    formatting: FormatProfile? = nil,
    options: RenderOptions? = nil
  ) {
    @Dependency(\.swiftSnapshotConfig) var snapshotConfig
    self.path = path
    self.formatting = formatting ?? snapshotConfig.getFormatProfile()
    self.options = options ?? snapshotConfig.getRenderOptions()
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
