# ``SwiftLiteralCore``

Configuration, formatting, paths, and writing files.

## Overview

The engine lives in `SwiftLiteralReflection` and turns a value into an expression. This
module surrounds it: it decides how the file is formatted, where it goes, and what the
extension around the expression looks like.

### Three steps

1. **Get a value.** Run the app, decode a response, reproduce the bug — whatever gives you
   the state you care about.

2. **Write it.**

   ```swift
   try Literal.write(order, named: "shippedOrder")
   ```

   `Order+shippedOrder.swift` appears in `__Snapshots__`, next to the file that called it.

3. **Commit it, then use it.**

   ```swift
   #expect(Order.shippedOrder.total == 59.98)
   ```

From then on `Order.shippedOrder` is ordinary Swift. Rename a property and it stops
compiling. <doc:WhatAndWhy> has the argument, and what it costs.

`Literal.write` does nothing in a release build. The call is safe to leave in place.

### Where to go next

- <doc:Limits>. What reflection cannot do, and what to do instead. Read this one.
- <doc:CustomRenderers>. For the types on that list.
- <doc:Formatting>. Making fixtures look like the rest of your code.

## Topics

### Start here

- <doc:WhatAndWhy>
- <doc:Limits>
- <doc:Architecture>
- <doc:Comparisons>

### Writing values

- ``Literal``

### Configuring

- ``LiteralConfig``
- ``LiteralConfigurationClient``
- ``FormatProfile``
- ``FormatConfigSource``
- <doc:Formatting>

### When reflection is not enough

- <doc:CustomRenderers>
