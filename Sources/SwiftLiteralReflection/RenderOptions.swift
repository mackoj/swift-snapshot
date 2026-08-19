/// Knobs that change what the rendered expression looks like.
///
/// Every option here exists to make output deterministic. Two runs over equal values
/// must produce byte-identical source, or the generated file churns in every diff.
public struct RenderOptions: Sendable, Equatable {
  /// Sort dictionary entries by key. Swift dictionaries have no stable order, so
  /// without this the same value renders differently on every run.
  public var sortDictionaryKeys: Bool

  /// Sort set elements. Same reason as `sortDictionaryKeys`.
  public var setDeterminism: Bool

  /// Byte count under which `Data` renders as a hex array. Above it, base64.
  public var dataInlineThreshold: Int

  /// Render enum cases as `.caseName` instead of `Type.caseName`.
  public var forceEnumDotSyntax: Bool

  public init(
    sortDictionaryKeys: Bool = true,
    setDeterminism: Bool = true,
    dataInlineThreshold: Int = 16,
    forceEnumDotSyntax: Bool = true
  ) {
    self.sortDictionaryKeys = sortDictionaryKeys
    self.setDeterminism = setDeterminism
    self.dataInlineThreshold = dataInlineThreshold
    self.forceEnumDotSyntax = forceEnumDotSyntax
  }

  /// The library defaults. Deterministic on every axis.
  public static let `default` = RenderOptions()
}
