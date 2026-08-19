import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@testable import SwiftLiteralReflection

/// Custom renderers, tested through the thing that uses them.
///
/// There is no setup and no teardown in this file. That is the point of the change: a
/// `ValueRenderers` is a value, so a test cannot leak one into the next test, and these
/// suites can run in any order and at the same time.
@Suite struct ValueRenderersTests {
  private struct Phone {
    let digits: [Int]
    var e164: String { "+" + digits.map(String.init).joined() }
  }

  private struct Contact {
    let name: String
    let phone: Phone
    let backup: Phone?
  }

  private func render(_ value: Any, with renderers: ValueRenderers) throws -> String {
    try ValueRenderer.render(value, context: RenderContext(renderers: renderers)).description
  }

  @Test func aRendererReplacesWhatReflectionWouldHaveWritten() throws {
    var renderers = ValueRenderers()
    renderers.register(Phone.self) { phone, _ in
      "Phone(e164: \(literal: phone.e164))"
    }

    #expect(try render(Phone(digits: [3, 3, 1]), with: renderers) == #"Phone(e164: "+331")"#)
  }

  @Test func withoutOneReflectionWins() throws {
    // Reflection sees the stored property, which is not what the initializer takes. This
    // is the case the renderer exists for.
    #expect(try render(Phone(digits: [3, 3, 1]), with: ValueRenderers()) == "Phone(digits: [3, 3, 1])")
  }

  @Test func rendererAppliesAtEveryDepthAndThroughOptionals() throws {
    var renderers = ValueRenderers()
    renderers.register(Phone.self) { phone, _ in
      "Phone(e164: \(literal: phone.e164))"
    }

    let contact = Contact(
      name: "Alice",
      phone: Phone(digits: [1]),
      backup: Phone(digits: [2])
    )

    // `backup` is a `Phone?`. Optionals are unwrapped before renderers are consulted, so
    // registering the wrapped type is enough.
    #expect(
      try render(contact, with: renderers)
        == #"Contact(name: "Alice", phone: Phone(e164: "+1"), backup: Phone(e164: "+2"))"#
    )
  }

  @Test func twoSetsOfRenderersDisagreeWithoutInterfering() throws {
    // The whole reason renderers moved out of a singleton.
    var loud = ValueRenderers()
    loud.register(Phone.self) { _, _ in #""LOUD""# }

    var quiet = ValueRenderers()
    quiet.register(Phone.self) { _, _ in #""quiet""# }

    let phone = Phone(digits: [7])

    #expect(try render(phone, with: loud) == #""LOUD""#)
    #expect(try render(phone, with: quiet) == #""quiet""#)
    #expect(try render(phone, with: loud) == #""LOUD""#)
  }

  @Test func registeringTheSameTypeTwiceKeepsTheSecond() throws {
    var renderers = ValueRenderers()
    renderers.register(Phone.self) { _, _ in #""first""# }
    renderers.register(Phone.self) { _, _ in #""second""# }

    #expect(try render(Phone(digits: [1]), with: renderers) == #""second""#)
  }

  @Test func lookupIsByExactType() throws {
    struct Other { let value: Int }

    var renderers = ValueRenderers()
    renderers.register(Phone.self) { _, _ in #""phone""# }

    #expect(try render(Other(value: 1), with: renderers) == "Other(value: 1)")
  }

  @Test func theRendererSeesWhereItIs() throws {
    var renderers = ValueRenderers()
    renderers.register(Phone.self) { _, context in
      "\(literal: context.path.joined(separator: "."))"
    }

    let contact = Contact(name: "A", phone: Phone(digits: [1]), backup: nil)

    #expect(try render(contact, with: renderers).contains(#""phone""#))
  }

  @Test func aProtocolConformanceRegistersToo() throws {
    enum PhoneRenderer: CustomValueRenderer {
      static func render(_ value: Phone, context: RenderContext) throws -> ExprSyntax {
        "Phone(e164: \(literal: value.e164))"
      }
    }

    var renderers = ValueRenderers()
    renderers.register(PhoneRenderer.self)

    #expect(try render(Phone(digits: [9]), with: renderers) == #"Phone(e164: "+9")"#)
  }

  @Test func registeringReturnsACopySoSetsCanBeBuiltInline() throws {
    let renderers = ValueRenderers()
      .registering(Phone.self) { phone, _ in "Phone(e164: \(literal: phone.e164))" }

    #expect(ValueRenderers().isEmpty)
    #expect(!renderers.isEmpty)
    #expect(try render(Phone(digits: [4]), with: renderers) == #"Phone(e164: "+4")"#)
  }

  @Test func aRendererThatThrowsFailsTheRender() throws {
    struct Boom: Error {}

    var renderers = ValueRenderers()
    renderers.register(Phone.self) { _, _ in throw Boom() }

    #expect(throws: Boom.self) {
      try render(Phone(digits: [1]), with: renderers)
    }
  }

  @Test func customRenderersRunConcurrentlyWithoutSharedState() async throws {
    var renderers = ValueRenderers()
    renderers.register(Phone.self) { phone, _ in "Phone(e164: \(literal: phone.e164))" }
    let shared = renderers

    await withTaskGroup(of: Bool.self) { group in
      for index in 0..<32 {
        group.addTask {
          let rendered = try? self.render(Phone(digits: [index]), with: shared)
          return rendered == #"Phone(e164: "+\#(index)")"#
        }
      }
      for await matched in group {
        #expect(matched)
      }
    }
  }
}
