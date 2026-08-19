# How this differs from the neighbours

Three libraries sit close to this one. They answer different questions.

## swift-snapshot-testing

[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) records
what your code produced, and tells you when it changes.

```swift
assertSnapshot(of: view, as: .image)
```

The recorded artifact is a reference. You do not build values out of it, you compare
against it. When the comparison fails, you look at the diff and decide whether the change
was intended.

SwiftLiteral records a value so you can build it again. The output is an input.

They do not overlap and they get on fine in the same test target. A common shape is a
SwiftLiteral fixture feeding a snapshot-testing assertion:

```swift
assertSnapshot(of: ProfileView(user: .testUser), as: .image)
```

The name collision was real, and it is why this library is no longer called SwiftSnapshot.

## swift-debug-snapshots

[swift-debug-snapshots](https://github.com/pointfreeco/swift-debug-snapshots) has a
`@DebugSnapshot` macro that reduces a model to an inert value, then logs and asserts on how
that value changes over time.

```
incrementButtonTapped():
    #1 FeatureModel.DebugSnapshot(
  -   count: 0,
  +   count: 1,
      favoriteNumbers: []
    )
```

It answers "what changed, and was that the change I meant?". Its output is a diff for a
person to read.

SwiftLiteral answers "how do I get this exact value back?". Its output is source for a
compiler to read. A `-` and `+` in a `CustomDump` diff are deliberately terse; a fixture
has to be complete, unambiguous, and buildable.

The engines differ for the same reason. `swift-debug-snapshots` uses
[CustomDump](https://github.com/pointfreeco/swift-custom-dump), which is tuned for legible
output. This one is tuned for output that type-checks: it emits `.some(nil)` where a dump
would print `nil`, and `UUID(uuidString: "…")!` where a dump would print the bare UUID.

If you want to watch state move, use theirs. If you want to pin state down, use this.

## JSON

The comparison people actually make. See <doc:WhatAndWhy>.

Short version: a JSON fixture is invisible to the compiler, so a rename breaks it silently
and you find out at runtime. A Swift fixture stops compiling and the compiler tells you
where.
