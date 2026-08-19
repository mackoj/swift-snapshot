# SwiftLiteral vs DebugSnapshots

SwiftLiteral and Point-Free's DebugSnapshots solve related but different problems.

## Different primary goals

- **SwiftLiteral**: generate compilable Swift fixture code from runtime values.
- **DebugSnapshots**: diff and assert state changes of mutable models over operations.

## Where each is strongest

### SwiftLiteral

- Reusable typed fixtures committed in source control
- Compile-time breakage when model APIs change
- Shared fixtures across tests, previews, and reproductions

### DebugSnapshots

- Exhaustive behavior assertions over model transitions
- Focused change diffs for debugging mutable state
- Method-invocation-centric diagnostics

## Practical guidance

Use SwiftLiteral when you need durable fixture data.  
Use DebugSnapshots when you need behavioral change assertions over time.  
In larger codebases, they can be complementary.

## Reflection engine note

SwiftLiteral currently relies on reflection as the stable default engine for custom types, with macro-expression rendering as an experimental opt-in path.
