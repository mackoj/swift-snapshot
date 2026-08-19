# ``SwiftLiteralCore``

Configuration, formatting, paths, and writing files.

## Overview

The engine lives in `SwiftLiteralReflection` and turns a value into an expression. This
module surrounds it: it decides how the file is formatted, where it goes, and what the
extension around the expression looks like.

```swift
try Literal.write(user, named: "testUser")
```

## Topics

### Start here

- <doc:WhatAndWhy>
- <doc:Architecture>
- <doc:Comparisons>

### Writing values

- ``Literal``

### Configuring

- ``LiteralConfig``
- ``FormatProfile``
- ``FormatConfigSource``
- <doc:Formatting>

### When reflection is not enough

- <doc:Limits>
- <doc:CustomRenderers>
