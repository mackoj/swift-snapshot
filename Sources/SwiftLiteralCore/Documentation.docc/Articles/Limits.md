# Limits

What reflection cannot do, and what the library does about it.

The rule throughout: when it cannot produce Swift that compiles, it throws. It does not
write a file and let you find out later.

## Reflection sees stored properties

That is all `Mirror` gives. So the library builds `Type(label: value, …)` from the stored
properties and assumes a memberwise initializer takes them.

When that assumption is wrong, the generated call is wrong.

```swift
struct Phone {
    private let digits: [Int]        // what reflection sees
    init(e164: String) { … }         // the only initializer
}
```

Reflection writes `Phone(digits: [3, 3, 6, …])`. There is no such initializer, so the file
does not build.

**What to do:** register a renderer. See <doc:CustomRenderers>.

## Some property wrappers are unreadable

A wrapper works if its value is reachable through `Mirror`:

- a stored `wrappedValue`
- a single stored property that a computed `wrappedValue` sits on top of

Both are common, and both work.

A wrapper does not work if it keeps its value behind a pointer or inside framework
machinery. `@Published` stores an `UnsafeMutablePointer`. SwiftUI's `@State` stores a box
the runtime owns. `Mirror` cannot read either.

An earlier version of this library tried anyway: it cast the pointer to a list of likely
types and, when none matched, wrote `nil` into the file. That is worse than failing.

**What to do:** mark the property `@LiteralIgnore`, or register a renderer for the wrapper.

## Classes with no stored properties

A class whose state lives in a superclass, in Objective-C storage, or in nothing at all
reflects as empty. The library throws rather than emit `Type()`, which would compile and
be wrong.

**What to do:** register a renderer.

## Reference identity is not preserved

Two properties pointing at the same object render as two separate initializer calls. The
generated fixture has two objects.

If identity matters, build the fixture by hand and let the library generate the pieces.

## Closures

A closure has no source form. Reflection cannot see its body, and there is nothing to
write down.

A property typed `Any` or `some P` is fine, incidentally: reflection reads the dynamic
type and writes that type's initializer, which type-checks in an `Any` position.

**What to do:** `@LiteralIgnore`, or a renderer that emits a stand-in.

## Sized integers render as bare literals

`Int8(42)` renders as `42`. In an `Int8` position the literal converts, and the short form
reads better.

The one place this could matter is a heterogeneous `[Any]`, where there is no expected type
to convert against. Fixtures of `[Any]` are rare enough that this is the right trade.

## Custom collections are the one guess

A `Collection` the standard library did not write renders as `TypeName([element, …])`.

That is right for `IdentifiedArray`, `OrderedSet`, and every collection wrapper that takes
an array in its initializer, which is nearly all of them. It is wrong for one that does
not, and this is the only place in the library that assumes a shape it cannot verify.

**What to do:** register a renderer.

## On a device there is nowhere obvious to write

The library builds for macOS, iOS, watchOS, and tvOS, and CI checks all four.

`Literal.source` works anywhere. It returns a string.

`Literal.write` needs a destination. Its default is `__Snapshots__` next to the file that
called it, resolved from `#filePath` — the path on the machine that compiled the code. In a
simulator that machine is yours, so the file lands in your source tree, which is the point.
On a device that path does not exist and the write fails with an I/O error.

**What to do:** on a device, pass a `directory:` inside the app's sandbox, or call
`Literal.source` and move the text yourself.

## Floating point round-trips, and says so

`Double` and `Float` render with Swift's own shortest round-tripping description, so the
value you get back is bit-identical. `Double.nan` and `Double.infinity` render as
themselves, since neither has a literal form.

Note that `Double.nan == Double.nan` is `false`. A fixture holding NaN will not compare
equal to itself, and that is arithmetic, not a bug here.
