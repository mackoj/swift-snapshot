# Custom renderers

When reflection cannot build a call that compiles, write the call yourself.

## When you need one

Reflection reads stored properties and assumes an initializer takes them. That covers most
types. It fails when the initializer wants something the stored properties are not.

```swift
struct Phone {
    private let digits: [Int]        // what reflection sees
    var e164: String { … }           // what the initializer wants
    init(e164: String) { … }
}
```

Reflection writes `Phone(digits: [3, 3, 6, …])`. There is no such initializer, so the
generated file does not build. The other cases are listed in <doc:Limits>.

## Writing one

```swift
import SwiftLiteral
import SwiftSyntax

ValueRendererRegistry.register(Phone.self) { phone, _ in
    "Phone(e164: \(literal: phone.e164))"
}
```

The closure returns `ExprSyntax`. `ExprSyntax` is `ExpressibleByStringInterpolation`, and
`\(literal:)` escapes the value properly, so a string with a quote in it does not break the
output.

The second argument is a `RenderContext`. It carries the render options in force and the
path to the value, which is useful in an error message.

## As a type

For something you register in more than one place, conform to `CustomValueRenderer`:

```swift
enum PhoneRenderer: CustomValueRenderer {
    static func render(_ value: Phone, context: RenderContext) throws -> ExprSyntax {
        "Phone(e164: \(literal: value.e164))"
    }
}

ValueRendererRegistry.register(PhoneRenderer.self)
```

## Rendering the parts

A renderer does not have to build everything by hand. Call back into the engine for the
pieces:

```swift
ValueRendererRegistry.register(Money.self) { money, context in
    let amount = try ValueRenderer.render(money.amount, context: context)
    return "Money(amount: \(amount), currency: .\(raw: money.currency.code))"
}
```

## Lookup is by exact type

A renderer registered for `Phone` applies to `Phone`, and to `Phone?` because optionals are
unwrapped before the registry is consulted. It does not apply to a subclass or to a
different generic specialisation. `Box<Int>` and `Box<String>` are two registrations.

## Reset between tests

The registry is global. A renderer registered by one test is still there in the next one,
and a test suite that only passes in one order is not a test suite.

```swift
@Suite struct MyTests {
    init() { ValueRendererRegistry.removeAll() }
}
```

## Registering is not the only option

If you control the type, `@LiteralIgnore` on the awkward property is often the smaller
change. A fixture does not have to carry every field to be useful.
