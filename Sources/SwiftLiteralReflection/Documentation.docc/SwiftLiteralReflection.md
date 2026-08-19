# ``SwiftLiteralReflection``

The engine. Value in, `ExprSyntax` out.

## Overview

```swift
let expression = try ValueRenderer.render(user)
// User(id: 42, name: "Alice", role: .admin)
```

No file I/O. No global state. A render is a pure function of the value and the
``RenderContext`` it is handed, so the same value with the same context renders the same
way every time, whatever else the process is doing.

The context carries four things: the ``RenderOptions`` in force, the ``ValueRenderers`` in
force, a breadcrumb path for error messages, and the class instances already open further
up the graph.

```swift
var renderers = ValueRenderers()
renderers.register(Phone.self) { phone, _ in
  "Phone(e164: \(literal: phone.e164))"
}

let expression = try ValueRenderer.render(
  contact,
  context: RenderContext(renderers: renderers)
)
```

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

**Names that resolve.** A nested type renders as `Order.Line`, not `Line`, which would not
resolve from a fixture sitting in an extension on something else. Inherited properties are
included, because `Mirror.children` stops at the class it was made from and a subclass
would otherwise lose everything its superclass declared.

**Not recursing forever.** Source is a tree; an object graph is not. Two objects pointing
at each other throw instead of exhausting the stack.

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
