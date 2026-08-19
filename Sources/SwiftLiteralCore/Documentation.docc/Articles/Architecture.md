# Architecture

Four targets. Each one does a single thing.

## The targets

| Target | Holds | Depends on |
|---|---|---|
| `SwiftLiteralReflection` | The engine. Value in, `ExprSyntax` out. | swift-syntax |
| `SwiftLiteralCore` | Configuration, formatting, paths, writing files. | the engine, swift-format |
| `SwiftLiteralMacros` | The compiler plugin. | swift-syntax |
| `SwiftLiteral` | Imports all of the above. | all of the above |

The engine is a separate product. If you want expressions and not files, depend on
`SwiftLiteralReflection` alone.

The split is not decoration. The engine has no file I/O and no global state, so a render is
a pure function of the value and the context it is handed. That is what makes it testable
in isolation, and isolation is what let the round-trip typecheck test exist.

## The pipeline

```
value
  │
  ├─ ValueRenderer          builds source text, then parses it once
  │
  ├─ CodeFormatter          wraps it in an extension, runs swift-format
  │
  ├─ PathResolver           decides which file, in which directory
  │
  └─ Literal.write          writes it
```

## Inside the engine

`ValueRenderer` builds a `String`, then parses that string into `ExprSyntax` once, at the
top. It does not assemble syntax nodes by hand at every level.

Two reasons. Building nodes for `Date(timeIntervalSince1970: 1.0)` takes twenty lines and
a string takes one. And the single parse at the end is a real check: if the text does not
parse, rendering throws rather than handing back a malformed tree.

Per value, in order:

1. **Optionals** are unwrapped first, so a renderer registered for `T` also covers `T?`.
2. **Custom renderers** from `ValueRenderers`.
3. **Macro-described types**, via `LiteralFields`. This is where `@LiteralRedact`,
   `@LiteralRename`, and `@LiteralIgnore` take effect, at every depth.
4. **Primitives and Foundation types.**
5. **Collections**, through `Mirror` rather than casts. Casting `[Int: String]` to
   `[AnyHashable: Any]` erases the key type, and the keys come out as strings.
6. **Reflection** over structs, classes, and enums.

If none of those can read the value, it throws `LiteralError` with the path to the value
and the name of the type. It does not substitute `nil`.

### What the context carries

Everything the engine needs, and nothing it could find another way:

| | |
|---|---|
| `options` | sorting, `Data` threshold, enum syntax |
| `renderers` | the custom renderers in force, as a value |
| `path` | a breadcrumb to the value, for error messages |
| open objects | the class instances already open further up the graph |

The last one is how a cycle is caught. Source is a tree and an object graph is not, so
`a.peer = b; b.peer = a` used to recurse until the stack ran out. The renderer throws when
it meets an instance it is already inside.

Renderers travel in the context rather than living in a registry so that two renders can
disagree about how to render a type, and neither has to clean up after itself.

## Configuration

`LiteralConfig` holds global settings behind a lock: output root, header, format profile,
render options, custom renderers. That is what an app configures at launch.

A render does not read it directly. It reads `LiteralConfigurationClient` through
`\.literalConfiguration`, whose live value reads `LiteralConfig` and whose test value is
the library defaults and nothing else.

The reason is concurrency. Tests run at the same time, and a process-global setting means
one test changing the format profile changes what another test renders. That failure is
timing-dependent: it passes locally and fails on CI, which is exactly what happened here
before the client existed.

Either way, the engine never reads any of it. Configuration is resolved once, at the top of
a render, and travels down as a value.
