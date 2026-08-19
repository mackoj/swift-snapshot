# SwiftLiteral

Take a value that exists at runtime. Write it back out as Swift source.

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
preview, in another fixture. It has autocomplete and jump-to-definition, because it is
code, not data.

---

## Why

Test data usually starts as JSON. JSON has one problem, and it is a bad one: the compiler
cannot see it.

Rename a property and the JSON keeps the old key. Nothing complains. The decode fails at
runtime, in a test, with a message about a missing key, and you go looking for which of
forty fixture files is stale.

```swift
struct User {
-   let name: String
+   let fullName: String
}
```

```json
{ "name": "Alice" }
```
The file is now wrong. Nothing says so until the test runs.

```swift
User(name: "Alice")
```
This does not build. The compiler points at the line and tells you what to do.

That is the whole idea. A fixture written in Swift is checked by the same compiler that
checks everything else you wrote.

The rest follows from it. No decoding step, so no decoding cost and no `try` in your test
setup. Readable diffs, because the fixture is text a person wrote the grammar for. One
place to look, because a fixture can reference another fixture.

## Where the value comes from

Anywhere. That is the point of taking it at runtime.

Catch a bug in the simulator, write the state that caused it straight into a fixture, and
now the regression test has the real thing instead of your reconstruction of it. Capture
a decoded API response once and stop hitting the network in tests. Take the state your app
is in when a screen looks wrong and hand it to a SwiftUI preview.

## Install

```swift
.package(url: "https://github.com/mackoj/swift-snapshot.git", from: "0.3.0")
```

```swift
.product(name: "SwiftLiteral", package: "swift-snapshot")
```

Swift 6.0. macOS 13, iOS 16, watchOS 9, tvOS 16. CI builds every one of them.

`Literal.source` works anywhere. `Literal.write` needs somewhere to write: on a simulator
the default path resolves against the machine that compiled the code, so it lands in your
source tree as expected. On a device it does not, and you should pass a `directory:` inside
the app's sandbox or use `Literal.source` and move the text yourself.

## Use

### Write a file

```swift
try Literal.write(user, named: "testUser")
```

The file lands in the first of these that is set:

1. the `directory:` argument
2. `LiteralConfig.setGlobalRoot(_:)`
3. the `SWIFT_SNAPSHOT_ROOT` environment variable
4. `__Snapshots__`, next to the file that called it

`write` throws. If the value cannot be rendered as compilable Swift, you get an error that
names the type and the path to it. You do not get a file that looks fine and does not
build.

`write` does nothing in a release build. Writing source files is something you do while
writing tests.

### Get the source without writing it

```swift
let code = try Literal.source(of: user, named: "testUser")
```

Useful when you want to assert on the text, or put it somewhere yourself.

### Add a header and a note

```swift
try Literal.write(
    product,
    named: "sampleProduct",
    header: "// Generated. Do not edit by hand.",
    context: "The product used by the pricing tests."
)
```

`header` goes at the top of the file. `context` becomes the doc comment on the property.

### The macro

Reflection sees stored properties and nothing else. It cannot see that a property is a
secret, or that the initializer takes a different label, or that a field is a cache you do
not want in the file. Those facts live in the source, so a macro reads them at compile
time.

```swift
import SwiftLiteral

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

```swift
extension User {
    static let testUser: User = User(id: "1", displayName: "Alice", apiKey: "***")
}
```

| Attribute | Does |
|---|---|
| `@SwiftLiteral(folder:)` | Adds `writeLiteral(named:)`. `folder` sets the output directory for this type. |
| `@LiteralIgnore` | Leaves the property out. |
| `@LiteralRename(_:)` | Uses a different argument label. |
| `@LiteralRedact(.mask("***"))` | Replaces the value with a literal. |
| `@LiteralRedact(.hash)` | Replaces the value with `"<hashed>"`. |

Redaction applies at every depth. A redacted property three structs down is still
redacted.

### Types it handles

Primitives, including every sized integer. `String`, `Character`, `Bool`, `Double`,
`Float`, and the special float values.

Arrays, dictionaries, sets, ranges. Keys keep their type: `[1: "one"]` renders as
`[1: "one"]`, not `["1": "one"]`.

`Date`, `UUID`, `URL`, `Data`, `Decimal`.

Optionals, including nested ones. `Int??.some(nil)` renders as `.some(nil)`, because that
is a different value from `nil`.

Structs, classes, and enums by reflection. Enum case names come from the runtime, so an
enum that overrides `description` still renders its real case.

Generic types, with their parameters.

### When reflection is not enough

Reflection reads stored properties. If a type's initializer does not take its stored
properties, reflection cannot build a call that compiles.

```swift
struct Phone {
    private let digits: [Int]        // what reflection sees
    var e164: String { … }           // what the initializer wants
    init(e164: String) { … }
}
```

Reflection would write `Phone(digits: [3, 3, 6, …])`, and there is no such initializer.
Write a renderer:

```swift
import SwiftSyntax

ValueRendererRegistry.register(Phone.self) { phone, _ in
    "Phone(e164: \(literal: phone.e164))"
}
```

The registry is global. Call `ValueRendererRegistry.removeAll()` in your test setup so a
renderer registered by one test does not leak into the next.

### Formatting

Generated files go through swift-format. Point it at your project's config and the
fixtures come out looking like the rest of your code, so the diff is about the data.

```swift
LiteralConfig.setFormatConfigSource(.editorconfig(URL(filePath: ".editorconfig")))
```

`.swift-format` works too:

```swift
LiteralConfig.setFormatConfigSource(.swiftFormat(URL(filePath: ".swift-format")))
```

Or set it directly:

```swift
LiteralConfig.setFormattingProfile(
    FormatProfile(indentStyle: .space, indentSize: 2)
)
```

### Determinism

Two runs over equal values produce the same bytes. Otherwise the fixture churns in every
diff and the whole thing is worse than JSON.

Dictionary keys sort. Set elements sort. `Data` under sixteen bytes inlines as hex, above
that as base64.

```swift
LiteralConfig.setRenderOptions(
    RenderOptions(sortDictionaryKeys: true, setDeterminism: true, dataInlineThreshold: 16)
)
```

### Configuration in tests

`LiteralConfig` is process-global. That is fine for an app and wrong for a test suite:
tests run concurrently, so one test setting a two-space `.editorconfig` changes what
another test renders, and the failure only shows up when the timing is unlucky.

So a render reads its configuration from a dependency, not from the globals. Its test value
is the library defaults and nothing else. To render with something else, say so:

```swift
import Dependencies

withDependencies {
    $0.literalConfiguration.formatProfile = { FormatProfile(indentSize: 2) }
} operation: {
    let code = try Literal.source(of: value, named: "fixture")
}
```

The override is a task local, so it applies to that test and no other.

## What it does not do

**It is not a mocking library.** It gives you the data a test consumes. It does not
observe calls, stub network responses, or assert on interactions. Keep your spies.

**It is not swift-snapshot-testing.** That library records what your code produced and
tells you when it changes. This one records a value so you can build it again. They answer
different questions and they get along fine in the same test target.

**It cannot read every property wrapper.** A wrapper that stores its value, or computes
`wrappedValue` on top of one stored property, works. A wrapper that keeps its value behind
a pointer or inside framework machinery — `@Published`, SwiftUI's `@State` — is not
readable through `Mirror`, and the library says so instead of guessing. Mark those
`@LiteralIgnore`.

**It cannot invent an initializer.** If the memberwise initializer is not what the type
offers, register a renderer.

## Layout

| Module | Holds |
|---|---|
| `SwiftLiteralReflection` | The engine. Value in, `ExprSyntax` out. No file I/O, no global state. |
| `SwiftLiteralCore` | Configuration, formatting, paths, writing files. |
| `SwiftLiteralMacros` | The compiler plugin. |
| `SwiftLiteral` | Imports all of the above. |

`SwiftLiteralReflection` is a product on its own, for anyone who wants expressions and not
files.

## Tests

```bash
swift test
```

The test that matters is `everySampleTypechecks`. It renders every sample in the matrix,
writes them next to the real type declarations, and runs `swiftc -typecheck` over both.

Parsing is not enough. `User(name: nil)` parses.

## License

MIT. See [LICENSE](LICENSE).

Built on [swift-syntax](https://github.com/swiftlang/swift-syntax) and
[swift-format](https://github.com/swiftlang/swift-format).
