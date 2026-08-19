# ``SwiftLiteral``

Take a value that exists at runtime. Write it back out as Swift source.

## Overview

```swift
let user = User(id: 42, name: "Alice", role: .admin)
try Literal.write(user, named: "testUser")
```

That writes `User+testUser.swift`:

```swift
import Foundation

extension User {
    static let testUser: User = User(id: 42, name: "Alice", role: .admin)
}
```

From then on `User.testUser` is ordinary Swift. Commit it. Diff it. Use it in a test, in a
preview, in another fixture. Rename `name` and it stops compiling, which is the whole
point: a JSON fixture would have gone quiet and failed at runtime instead.

## Where things live

Importing `SwiftLiteral` gives you everything. This module itself declares only the
attributes; the rest comes from the two it re-exports.

| Module | Holds |
|---|---|
| `SwiftLiteralReflection` | The engine. Value in, `ExprSyntax` out. `ValueRenderer`, `ValueRendererRegistry`, `RenderOptions`. |
| `SwiftLiteralCore` | `Literal`, `LiteralConfig`, `FormatProfile`, and every article. |
| `SwiftLiteralMacros` | The compiler plugin. |

Start with the articles on `SwiftLiteralCore`.

## Describing a type

Reflection sees stored properties and nothing else. It cannot see that a property is a
secret, that the initializer takes a different label, or that a field is a cache you do not
want in the file. Those facts live in the source, so the macro reads them at compile time.

```swift
@SwiftLiteral(folder: "Fixtures")
struct User {
    let id: String

    @LiteralRename("displayName")
    let name: String

    @LiteralRedact(.mask("***"))
    let apiKey: String

    @LiteralIgnore
    let cache: [String: Any]
}

try user.writeLiteral(named: "testUser")
```

Redaction applies at every depth. A redacted property three structs down is still redacted.

## Topics

### Attributes

- ``SwiftLiteral(folder:)``
- ``LiteralIgnore()``
- ``LiteralRename(_:)``
- ``LiteralRedact(_:)``
- ``RedactionStyle``
