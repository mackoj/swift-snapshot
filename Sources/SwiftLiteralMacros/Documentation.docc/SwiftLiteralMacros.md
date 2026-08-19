# ``SwiftLiteralMacros``

The compiler plugin behind `@SwiftLiteral`.

## Overview

This is the implementation target. You do not import it. Import `SwiftLiteral` and use the
attributes.

## Why a macro exists at all

Reflection sees stored properties and nothing else. It cannot see that a property is a
secret, that the initializer takes a different label, or that a field is a cache you do not
want in the file. Those facts live in the source, not in the value.

So the macro reads them at compile time and emits one method:

```swift
func __swiftLiteral_fields() -> [LiteralField]
```

It returns the fields in declaration order, with `@LiteralIgnore` already dropped,
`@LiteralRename` already applied to the label, and `@LiteralRedact` already replaced with
its stand-in. The renderer takes that list over reflection whenever it is available, at
every depth, so a redacted property three structs down is still redacted.

`@SwiftLiteral` also adds `writeLiteral(named:)`, which is `Literal.write` with the type's
`folder` filled in.

## What it deliberately does not do

An earlier version generated a second method that built the whole initializer call as a
`String` at compile time. It produced things like `User(id: 123, name: Alice)` — unquoted
strings, not compilable Swift — because a macro cannot know how to escape a value it has
only seen the name of.

Escaping is a runtime job. The macro reports facts; the renderer writes source.

## Topics

### Macros

- ``SwiftLiteralMacro``
- ``LiteralIgnoreMacro``
- ``LiteralRenameMacro``
- ``LiteralRedactMacro``
