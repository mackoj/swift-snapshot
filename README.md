# SwiftLiteral

[![CI](https://github.com/mackoj/swift-snapshot/actions/workflows/ci.yml/badge.svg)](https://github.com/mackoj/swift-snapshot/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmackoj%2Fswift-snapshot%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mackoj/swift-snapshot)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmackoj%2Fswift-snapshot%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mackoj/swift-snapshot)

Take a value that exists at runtime. Write it back out as Swift source.

```swift
// A real response, with forty fields you are not going to type by hand.
let order = try JSONDecoder().decode(Order.self, from: data)

try Literal.write(order, named: "shippedOrder")
```

`Order+shippedOrder.swift`, next to your test:

```swift
import Foundation

extension Order {
    static let shippedOrder: Order = Order(
        id: UUID(uuidString: "8C6D4E2A-0000-4000-8000-1B2C3D4E5F60")!,
        placedAt: Date(timeIntervalSince1970: 1710000000.0),
        status: .shipped,
        lines: [Order.Line(sku: "WDG-001", quantity: 2, unitPrice: Decimal(string: "29.99")!)]
    )
}
```

That block is not written by hand. `ReadmeExampleTests` renders it and asserts on the
text, so if the output changes the README fails the build.

Commit it. `Order.shippedOrder` is ordinary Swift from then on. It has autocomplete.
It needs no decoding.

Rename a property and it stops compiling. The compiler tells you where.

## Contents

- [Why](#why)
- [What it costs](#what-it-costs)
- [Install](#install)
- [Quick start](#quick-start)
- [Writing values](#writing-values)
- [Describing a type](#describing-a-type)
- [What it renders](#what-it-renders)
- [When reflection is not enough](#when-reflection-is-not-enough)
- [Formatting](#formatting)
- [Determinism](#determinism)
- [In tests](#in-tests)
- [What it does not do](#what-it-does-not-do)
- [Modules](#modules)

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

This does not build. The compiler points at the line.

A fixture written in Swift is checked by the same compiler that checks everything else you
wrote.

Three things follow from that. There is no decoding step, so no decoding cost and no `try`
in your setup. The diff is legible, because a person designed this grammar to be read. One
fixture can reference another, so there is one place to look.

### Where the value comes from

Anywhere. That is the point of taking it at runtime.

- Catch a bug in the simulator. Write the state that caused it straight into a fixture, and
  the regression test has the real thing instead of your reconstruction of it a day later.
- Decode an API response once. Stop hitting the network in tests.
- Take the state a screen is in when it looks wrong. Hand it to a SwiftUI preview.

## What it costs

A Swift fixture is worse than JSON at four things.

**It breaks the build.** That is the feature, and it is also the cost. Rename a property
mid-refactor and every fixture stops compiling before you are ready to deal with them. JSON
lets you defer.

**It compiles.** Fixtures are source, so they add to build time. A large one is a large
file the compiler now type-checks on every build. JSON costs nothing until it is read.

**Editing means regenerating.** Changing one number in a JSON file takes seconds. Changing
one number in a fixture means editing generated code by hand, or running the thing again.

**It is Swift only.** A JSON fixture can go to a backend team, a test suite in another
language, or a bug report. A Swift fixture cannot leave the project.

If your fixtures are shared across languages, or change more often than the types do, JSON
is the better trade.

## Install

```swift
.package(url: "https://github.com/mackoj/swift-snapshot.git", from: "0.3.1")
```

```swift
.product(name: "SwiftLiteral", package: "swift-snapshot")
```

Swift 6.0. macOS 13, iOS 16, watchOS 9, tvOS 16. CI builds every one of them.

**Generate on macOS or in the simulator.** That is the design. The tool writes a file into
your source tree so you can commit it, and those are the two places your source tree
exists. A device build links fine. The default output path comes from `#filePath`,
the compiling machine's path. That path does not exist on a phone.

<details>
<summary>If Xcode says <code>Unable to resolve module dependency: 'SwiftSyntax'</code></summary>

That is Xcode's module scanner failing on modules it has already built, not a platform
problem. It shows up on packages that have both a macro plugin and a library on
swift-syntax, which is this package's shape.

Clear the caches and rebuild:

```bash
rm -rf ~/Library/Caches/org.swift.swiftpm ~/Library/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/<YourProject>-*
```

SwiftPM keeps prebuilt swift-syntax artifacts in that first directory. A partial one
produces exactly this error. Check `xcode-select -p` points at an Xcode and not a
standalone toolchain while you are there.

</details>

## Quick start

1. **Get a value.** Run the app, decode a response, reproduce the bug. Whatever gives you
   the state you care about.

2. **Write it.** In a test, a preview, or a debug button:

   ```swift
   try Literal.write(order, named: "shippedOrder")
   ```

   The file appears in `__Snapshots__`, next to the file that called it.

3. **Commit it, then use it.**

   ```swift
   #expect(Order.shippedOrder.total == 59.98)
   ```

Delete the `write` call, or leave it. It does nothing in a release build.

## Writing values

### Write a file

```swift
try Literal.write(order, named: "shippedOrder")
```

The file lands in the first of these that is set:

1. the `directory:` argument
2. `LiteralConfig.setGlobalRoot(_:)`
3. the `SWIFT_SNAPSHOT_ROOT` environment variable
4. `__Snapshots__`, next to the file that called it

`write` throws. If a value cannot be rendered as compilable Swift you get an error naming
the type and the path to it. You do not get a file that looks fine and does not build.

### Get the source without writing it

```swift
let code = try Literal.source(of: order, named: "shippedOrder")
```

For asserting on the text, or putting it somewhere yourself.

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

### Import another module

The generated file imports Foundation. If the fixture mentions a type from somewhere else,
say so. Reflection sees the type's name, not which module it came from.

```swift
try Literal.write(order, named: "shippedOrder", additionalImports: ["MyModels"])
```

## Describing a type

Reflection sees stored properties and nothing else. It cannot see that a property is a
secret, that the initializer takes a different label, or that a field is a cache you do not
want in the file. Those facts live in the source, so a macro reads them at compile time.

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

**Redaction applies at every depth.** A redacted property three structs down is still
redacted.

## What it renders

| | |
|---|---|
| Primitives | `String`, `Character`, `Bool`, `Double`, `Float`, every sized integer, and the special float values |
| Collections | arrays, dictionaries, sets, ranges |
| Tuples | labelled and unlabelled |
| Foundation | `Date`, `UUID`, `URL`, `Data`, `Decimal`, `Locale`, `TimeZone` |
| Optionals | including nested ones |
| Your types | structs, classes, enums, generics |

Some details that are easy to get wrong, and are covered by tests:

- Dictionary keys keep their type. `[1: "one"]` renders as `[1: "one"]`, not `["1": "one"]`.
- Enum case names come from the runtime, so an enum that overrides `description` still
  renders its real case.
- `Int??.some(nil)` renders as `.some(nil)`, because that is not the same value as `nil`.
- Inherited properties are included. A subclass renders its superclass's state too.
- Nested types keep their path. `Order.Line`, not `Line`, which would not resolve.
- `Double` round-trips exactly.

## When reflection is not enough

Reflection reads stored properties and assumes an initializer takes them. When it does not:

```swift
struct Phone {
    private let digits: [Int]        // what reflection sees
    var e164: String { … }           // what the initializer wants
    init(e164: String) { … }
}
```

Reflection would write `Phone(digits: [3, 3, 1])`, and there is no such initializer. Write
a renderer:

```swift
import SwiftSyntax

LiteralConfig.registerRenderer(Phone.self) { phone, _ in
    "Phone(e164: \(literal: phone.e164))"
}
```

In a test, scope them instead. Renderers travel in the render context, so two tests can
disagree about how to render a type and neither has to clean up:

```swift
let renderers = ValueRenderers().registering(Phone.self) { phone, _ in
    "Phone(e164: \(literal: phone.e164))"
}

withDependencies {
    $0.literalConfiguration.renderers = { renderers }
} operation: {
    let code = try Literal.source(of: contact, named: "testContact")
}
```

## Formatting

Generated files go through swift-format. Point it at your project's config and fixtures
come out looking like the rest of your code, so the diff is about the data.

```swift
LiteralConfig.setFormatConfigSource(.editorconfig(URL(filePath: ".editorconfig")))
```

`.swift-format` works too:

```swift
LiteralConfig.setFormatConfigSource(.swiftFormat(URL(filePath: ".swift-format")))
```

Or set it directly:

```swift
LiteralConfig.setFormattingProfile(FormatProfile(indentStyle: .space, indentSize: 2))
```

## Determinism

Two runs over equal values produce the same bytes. Otherwise the fixture churns in every
diff and the whole thing is worse than JSON.

Dictionary keys sort. Set elements sort. `Data` under sixteen bytes inlines as hex, above
that as base64.

```swift
LiteralConfig.setRenderOptions(
    RenderOptions(sortDictionaryKeys: true, setDeterminism: true, dataInlineThreshold: 16)
)
```

## In tests

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

**It is not a mocking library.** It gives you the data a test consumes. It does not observe
calls, stub network responses, or assert on interactions. Keep your spies.

**It is not swift-snapshot-testing.** That library records what your code produced and tells
you when it changes. This one records a value so you can build it again. Different
questions, and they get along fine in the same test target.

**It cannot read every property wrapper.** A wrapper that stores its value, or computes
`wrappedValue` on top of one stored property, works. `@Published` and SwiftUI's `@State`
keep their value somewhere `Mirror` cannot reach. The library says so instead of guessing.
Mark those `@LiteralIgnore`.

**It cannot write down a cycle.** Source is a tree; an object graph is not. Two objects
pointing at each other throw rather than recurse forever.

**It cannot invent an initializer.** If the memberwise initializer is not what the type
offers, register a renderer.

Every limit, with what to do about each, is in the
[Limits](Sources/SwiftLiteralCore/Documentation.docc/Articles/Limits.md) article.

## Modules

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

The one that matters is `everySampleTypechecks`. It renders every sample in the matrix,
writes them next to the real type declarations, and runs `swiftc -typecheck` over both.

Parsing is not enough. `User(name: nil)` parses.

## License

MIT. See [LICENSE](LICENSE).

Built on [swift-syntax](https://github.com/swiftlang/swift-syntax) and
[swift-format](https://github.com/swiftlang/swift-format).
