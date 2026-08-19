# Stability and Support Tiers

This project now uses explicit support tiers so teams can choose predictable behavior first.

## Stable

These areas are the default path and should be preferred:

- Built-in primitives and Foundation rendering
- Collection rendering with deterministic ordering
- Reflection fallback for custom model types
- Top-level `@SwiftLiteral` field extraction via `__swiftLiteral_fields()` (ordered fields, deterministic transforms)
- File export workflow and formatting integration

## Experimental

These areas are available but opt-in:

- Macro-generated expression-string rendering via `RenderOptions.useMacroGeneratedExpressions = true`

This path can fail to parse in edge cases and will fall back to reflection.

## Deprecated

- Direct dependence on `LiteralFields` expression strings as the primary rendering strategy

Migration path:

1. Keep `useMacroGeneratedExpressions = false` (default).
2. Use built-in renderers/reflection for most types.
3. Use `ValueRendererRegistry` for any type needing strict custom output.
