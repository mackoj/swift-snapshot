import Testing
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

@testable import SwiftLiteralReflection

/// Tests for ValueRendererRegistry
@Suite(.serialized) struct ValueRendererRegistryTests {
  init() { ValueRendererRegistry.removeAll() }

    
    // MARK: - Basic Registration Tests
    
    /// Test registering a custom renderer for a simple type
    @Test func registerCustomRenderer() throws {
      struct CustomType {
        let value: String
      }
      
      // Register a custom renderer
      ValueRendererRegistry.register(CustomType.self) { value, context in
        ExprSyntax(stringLiteral: "\"\(value.value)\"")
      }
      
      // Verify the renderer is registered
      let testValue = CustomType(value: "test")
      let context = RenderContext()
      let renderer = ValueRendererRegistry.shared.renderer(for: testValue)
      
      #expect(renderer != nil)
      
      if let renderer = renderer {
        let result = try renderer(testValue, context)
        #expect(result.description.contains("test"))
      }
    }
    
    /// Test that different types can have different renderers
    @Test func registerMultipleRenderers() throws {
      struct TypeA {
        let value: Int
      }
      
      struct TypeB {
        let value: String
      }
      
      // Register renderers for both types
      ValueRendererRegistry.register(TypeA.self) { value, context in
        ExprSyntax(stringLiteral: "TypeA(\(value.value))")
      }
      
      ValueRendererRegistry.register(TypeB.self) { value, context in
        ExprSyntax(stringLiteral: "TypeB(\"\(value.value)\")")
      }
      
      // Verify both renderers work independently
      let valueA = TypeA(value: 42)
      let valueB = TypeB(value: "hello")
      let context = RenderContext()
      
      let rendererA = ValueRendererRegistry.shared.renderer(for: valueA)
      let rendererB = ValueRendererRegistry.shared.renderer(for: valueB)
      
      #expect(rendererA != nil)
      #expect(rendererB != nil)
      
      if let rendererA = rendererA {
        let resultA = try rendererA(valueA, context)
        #expect(resultA.description.contains("TypeA"))
        #expect(resultA.description.contains("42"))
      }
      
      if let rendererB = rendererB {
        let resultB = try rendererB(valueB, context)
        #expect(resultB.description.contains("TypeB"))
        #expect(resultB.description.contains("hello"))
      }
    }
    
    /// Test that registering a renderer overwrites previous registration
    @Test func registerOverwritesPrevious() throws {
      struct OverwriteType {
        let value: Int
      }
      
      // Register first renderer
      ValueRendererRegistry.register(OverwriteType.self) { value, context in
        ExprSyntax(stringLiteral: "First(\(value.value))")
      }
      
      // Register second renderer (should overwrite)
      ValueRendererRegistry.register(OverwriteType.self) { value, context in
        ExprSyntax(stringLiteral: "Second(\(value.value))")
      }
      
      let testValue = OverwriteType(value: 100)
      let context = RenderContext()
      let renderer = ValueRendererRegistry.shared.renderer(for: testValue)
      
      #expect(renderer != nil)
      
      if let renderer = renderer {
        let result = try renderer(testValue, context)
        #expect(result.description.contains("Second"))
        #expect(!result.description.contains("First"))
      }
    }
    
    // MARK: - Renderer Not Found Tests
    
    /// Test that unregistered types return nil renderer
    @Test func unregisteredTypeReturnsNil() {
      struct UnregisteredType {
        let value: String
      }
      
      let testValue = UnregisteredType(value: "test")
      let renderer = ValueRendererRegistry.shared.renderer(for: testValue)
      
      #expect(renderer == nil)
    }
    
    // MARK: - Error Handling Tests
    
    /// Test that renderer throws error for wrong type
    @Test func rendererThrowsForWrongType() throws {
      struct TypeA {
        let value: Int
      }
      
      struct TypeB {
        let value: Int
      }
      
      // Register renderer for TypeA
      ValueRendererRegistry.register(TypeA.self) { value, context in
        ExprSyntax(stringLiteral: "\(value.value)")
      }
      
      // Try to use TypeA's renderer with TypeB
      let valueA = TypeA(value: 42)
      let valueB = TypeB(value: 42)
      let context = RenderContext()
      
      if let renderer = ValueRendererRegistry.shared.renderer(for: valueA) {
        // This should work
        let result = try renderer(valueA, context)
        #expect(result.description.contains("42"))
        
        // This should throw an error
        #expect(throws: LiteralError.self) {
          try renderer(valueB, context)
        }
      } else {
        Issue.record("Expected renderer to be registered")
      }
    }
    
    // MARK: - Context Usage Tests
    
    /// Test that renderer receives and can use context
    @Test func rendererUsesContext() throws {
      struct ContextAwareType {
        let value: String
      }
      
      // Register renderer that uses context
      ValueRendererRegistry.register(ContextAwareType.self) { value, context in
        let pathInfo = context.path.isEmpty ? "root" : context.path.joined(separator: ".")
        return ExprSyntax(stringLiteral: "\"\(value.value) at \(pathInfo)\"")
      }
      
      let testValue = ContextAwareType(value: "test")
      let context1 = RenderContext(path: ["user", "address"])
      
      if let renderer = ValueRendererRegistry.shared.renderer(for: testValue) {
        let result = try renderer(testValue, context1)
        #expect(result.description.contains("user.address"))
      } else {
        Issue.record("Expected renderer to be registered")
      }
    }
    
    // MARK: - Protocol-based Registration Tests
    
    /// Test registering a renderer that conforms to CustomValueRenderer
    @Test func registerProtocolBasedRenderer() throws {
      struct ProtocolType {
        let value: Int
      }
      
      struct ProtocolRenderer: CustomValueRenderer {
        typealias Value = ProtocolType
        
        static func render(_ value: ProtocolType, context: RenderContext) throws -> ExprSyntax {
          ExprSyntax(stringLiteral: "Protocol(\(value.value))")
        }
      }
      
      // Register using protocol-based registration
      ValueRendererRegistry.register(ProtocolRenderer.self)
      
      let testValue = ProtocolType(value: 999)
      let context = RenderContext()
      let renderer = ValueRendererRegistry.shared.renderer(for: testValue)
      
      #expect(renderer != nil)
      
      if let renderer = renderer {
        let result = try renderer(testValue, context)
        #expect(result.description.contains("Protocol"))
        #expect(result.description.contains("999"))
      }
    }
    
    // MARK: - Thread Safety Tests
    
    /// Test that registry can be accessed from multiple threads
    @Test func threadSafetyBasicTest() async throws {
      struct ThreadTestType {
        let id: Int
      }
      
      // Register from main thread
      ValueRendererRegistry.register(ThreadTestType.self) { value, context in
        ExprSyntax(stringLiteral: "Thread(\(value.id))")
      }
      
      // Access from multiple tasks
      await withTaskGroup(of: Bool.self) { group in
        for i in 0..<10 {
          group.addTask {
            let value = ThreadTestType(id: i)
            let renderer = ValueRendererRegistry.shared.renderer(for: value)
            return renderer != nil
          }
        }
        
        var allSucceeded = true
        for await success in group {
          allSucceeded = allSucceeded && success
        }
        
        #expect(allSucceeded)
      }
    }
    
    // MARK: - Transformed Value Pattern Tests
    
    /// Test custom renderer for types with transformed/destroyed initialization values
    @Test func transformedValuePattern() throws {
      // Type that transforms input during initialization
      struct Bizarro {
        let transformed: Int
        
        // Primary initializer transforms input - original value is lost
        init(_ content: String) {
          self.transformed = content.hash
        }
        
        // Alternative initializer for reconstruction
        init(whyAreYouSoooMean transformed: Int) {
          self.transformed = transformed
        }
      }
      
      // Register custom renderer using the alternative initializer
      ValueRendererRegistry.register(Bizarro.self) { instance, context in
        ExprSyntax(stringLiteral: "Bizarro(whyAreYouSoooMean: \(instance.transformed))")
      }
      
      // Create instance with primary initializer
      let original = Bizarro("Pikachu")
      let context = RenderContext()
      
      // Verify renderer is registered
      let renderer = ValueRendererRegistry.shared.renderer(for: original)
      #expect(renderer != nil)
      
      // Verify the rendered output uses the alternative initializer
      if let renderer = renderer {
        let result = try renderer(original, context)
        let output = result.description
        
        // Should use the alternative initializer
        #expect(output.contains("Bizarro(whyAreYouSoooMean:"))
        #expect(output.contains("\(original.transformed)"))
        
        // Should NOT try to use the original string (which is lost)
        #expect(!output.contains("Pikachu"))
      }
    }
  }
