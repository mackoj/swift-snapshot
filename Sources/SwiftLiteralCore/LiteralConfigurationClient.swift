import Dependencies
import Foundation
import SwiftLiteralReflection

/// The configuration a render reads, as a dependency.
///
/// ``LiteralConfig`` is process-global. That is fine for an app and wrong for a test
/// suite: two tests running at the same time share it, so one test setting a two-space
/// `.editorconfig` changes what another test renders. That failure is timing-dependent,
/// which means it passes locally and fails on CI.
///
/// This client is the seam. In a test, scope the configuration to the test:
///
/// ```swift
/// withDependencies {
///   $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
/// } operation: {
///   let code = try Literal.source(of: value, named: "fixture")
/// }
/// ```
///
/// Closures rather than plain values, because the live implementation has to read the
/// globals at the moment of the render. A stored value would be cached at first access
/// and stop tracking ``LiteralConfig``.
public struct LiteralConfigurationClient: Sendable {
  public var renderOptions: @Sendable () -> RenderOptions
  public var formatProfile: @Sendable () -> FormatProfile
  public var formatConfigSource: @Sendable () -> FormatConfigSource?
  public var globalRoot: @Sendable () -> URL?
  public var globalHeader: @Sendable () -> String?

  public init(
    renderOptions: @escaping @Sendable () -> RenderOptions,
    formatProfile: @escaping @Sendable () -> FormatProfile,
    formatConfigSource: @escaping @Sendable () -> FormatConfigSource?,
    globalRoot: @escaping @Sendable () -> URL?,
    globalHeader: @escaping @Sendable () -> String?
  ) {
    self.renderOptions = renderOptions
    self.formatProfile = formatProfile
    self.formatConfigSource = formatConfigSource
    self.globalRoot = globalRoot
    self.globalHeader = globalHeader
  }
}

extension LiteralConfigurationClient {
  /// Reads ``LiteralConfig``, which is what an app configures.
  public static let live = LiteralConfigurationClient(
    renderOptions: { LiteralConfig.renderOptions() },
    formatProfile: { LiteralConfig.formattingProfile() },
    formatConfigSource: { LiteralConfig.getFormatConfigSource() },
    globalRoot: { LiteralConfig.getGlobalRoot() },
    globalHeader: { LiteralConfig.getGlobalHeader() }
  )

  /// Library defaults, and nothing else.
  ///
  /// This is the test value on purpose. A test gets four-space indentation, deterministic
  /// ordering, and no global root, whatever any other test is doing at the same moment.
  /// A test that wants something else says so with `withDependencies`.
  public static let `default` = LiteralConfigurationClient(
    renderOptions: { .default },
    formatProfile: { .default },
    formatConfigSource: { nil },
    globalRoot: { nil },
    globalHeader: { nil }
  )
}

private enum LiteralConfigurationKey: DependencyKey {
  static let liveValue = LiteralConfigurationClient.live
  static let testValue = LiteralConfigurationClient.default
  static let previewValue = LiteralConfigurationClient.live
}

extension DependencyValues {
  /// The configuration the next render will read.
  public var literalConfiguration: LiteralConfigurationClient {
    get { self[LiteralConfigurationKey.self] }
    set { self[LiteralConfigurationKey.self] = newValue }
  }
}
