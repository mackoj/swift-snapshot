# What this is, and why

Take a value that exists at runtime. Write it back out as Swift source.

## The problem

Test data usually starts as JSON. JSON has one problem, and it is a bad one: the compiler
cannot see it.

Rename a property and the JSON keeps the old key. Nothing complains at build time. The
decode fails at runtime, in a test, with a message about a missing key. Then you go
looking for which of forty fixture files is stale.

The cost is not the fix. The cost is that the failure arrives late, in a place that does
not tell you where the mistake was.

## The move

Write the fixture in Swift instead.

```swift
extension User {
    static let testUser: User = User(id: 42, name: "Alice", role: .admin)
}
```

Rename `name` now and this file stops compiling. The compiler points at the line. The
mistake is found by the same machinery that finds every other mistake you make.

Everything else follows from that one property.

**No decoding.** The value is already the value. No `try`, no `Data`, no bundle lookup, no
`JSONDecoder` in your test setup.

**Readable diffs.** A person designed this grammar to be read. `role: .admin` is legible
in a pull request in a way a base64 blob is not.

**One place to look.** A fixture is a normal static property, so one fixture can reference
another. `User.testUser` inside `Order.testOrder` inside `Cart.testCart`.

**It works outside tests.** SwiftUI previews want realistic data more than tests do, and a
static property is the easiest thing in the world to hand a preview.

## Where the value comes from

Anywhere. That is the point of taking it at runtime.

You catch a bug in the simulator with a specific piece of state on screen. Write that
state into a fixture and the regression test has the real thing, not your reconstruction
of it a day later.

You have an API you would rather not call in tests. Decode the response once, write it out,
and the fixture is a typed value from then on.

You have a screen that looks wrong at one particular size, in one particular locale, with
one particular user. Take that state and hand it to a preview.

## What it costs

A Swift fixture is worse than JSON at four things.

**It breaks the build.** That is the feature, and it is also the cost. Rename a property
mid-refactor and every fixture stops compiling before you are ready to deal with them. JSON
lets you defer.

**It compiles.** Fixtures are source, so they add to build time. A large one is a large
file the compiler type-checks on every build. JSON costs nothing until it is read.

**Editing means regenerating.** Changing one number in a JSON file takes seconds. Changing
one number in a fixture means editing generated code by hand, or running the thing again.

**It is Swift only.** A JSON fixture can go to a backend team, a test suite in another
language, or a bug report. A Swift fixture cannot leave the project.

If your fixtures are shared across languages, or change more often than the types do, JSON
is the better trade.

Reflection has limits on top of that. See <doc:Limits>.

## See also

- <doc:Architecture>
- <doc:Comparisons>
- <doc:Limits>
- <doc:CustomRenderers>
