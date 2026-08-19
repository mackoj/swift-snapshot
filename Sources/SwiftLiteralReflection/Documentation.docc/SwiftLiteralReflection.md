# ``SwiftLiteralReflection``

The engine. Value in, `ExprSyntax` out.

## Overview

```swift
let expression = try ValueRenderer.render(user)
// User(id: 42, name: "Alice", role: .admin)
```

No file I/O. No global configuration. Everything the renderer needs arrives in a
``RenderContext``, so the same value with the same options renders the same way every
time, whatever else the process is doing.

Depend on this module alone if you want expressions and not files.

## How it works

The renderer builds source text, then parses it once at the top. It does not assemble
syntax nodes by hand at every level. If the text does not parse, rendering throws.

Per value, in order:

1. **Optionals** are unwrapped first, so a renderer registered for `T` also covers `T?`.
2. **Custom renderers** from ``ValueRenderers``.
3. **Macro-described types**, via ``LiteralFields``.
4. **Primitives and Foundation types.**
5. **Collections**, through `Mirror` rather than casts.
6. **Reflection** over structs, classes, and enums.

If none of them can read the value, it throws. It does not substitute `nil` and hand back
something that looks fine.

## What it is careful about

**Determinism.** Dictionaries and sets have no stable order in Swift, so both are sorted
before rendering. A fixture that reorders itself on every run is worse than no fixture.

**Key types.** Collections go through `Mirror`, not through `as? [AnyHashable: Any]`. That
cast erases the key type, and `[1: "one"]` comes back as `["1": "one"]`, which is a
different value and does not compile.

**Enum case names.** Taken from the runtime, not from `String(describing:)`. A
`CustomStringConvertible` enum returns whatever it likes from `description`, and that text
is not a case name.

**Round-tripping.** `Double` and `Float` use Swift's shortest round-tripping description,
so the value you read back is bit-identical. `Int??.some(nil)` renders as `.some(nil)`,
because that is not the same value as `nil`.

## Topics

### Rendering

- ``ValueRenderer``
- ``RenderContext``
- ``RenderOptions``

### Extending

- ``ValueRenderers``
- ``CustomValueRenderer``

### Macro support

- ``LiteralFields``
- ``LiteralField``

### Errors

- ``LiteralError``
