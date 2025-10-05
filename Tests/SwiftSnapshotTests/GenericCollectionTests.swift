import Testing
import Foundation

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for generic Collection types support
  @Suite struct GenericCollectionTests {
    
    // MARK: - Simple Generic Collection Tests
    
    /// Test rendering a simple generic collection wrapper
    @Test func simpleGenericCollection() throws {
      struct GenericWrapper<Element>: Collection {
        let elements: [Element]
        
        init(_ elements: [Element]) {
          self.elements = elements
        }
        
        typealias Index = Array<Element>.Index
        var startIndex: Index { elements.startIndex }
        var endIndex: Index { elements.endIndex }
        subscript(position: Index) -> Element { elements[position] }
        func index(after i: Index) -> Index { elements.index(after: i) }
      }
      
      let wrapper = GenericWrapper([1, 2, 3, 4, 5])
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: wrapper,
        variableName: "testWrapper"
      )
      
      // Should contain the type name with generic parameter
      #expect(code.contains("GenericWrapper<Int>"))
      // Should contain the elements
      #expect(code.contains("1"))
      #expect(code.contains("2"))
      #expect(code.contains("3"))
    }
    
    /// Test rendering a generic collection with String elements
    @Test func genericCollectionWithStrings() throws {
      struct StringCollection<T>: Collection {
        let items: [T]
        
        init(_ items: [T]) {
          self.items = items
        }
        
        typealias Index = Array<T>.Index
        var startIndex: Index { items.startIndex }
        var endIndex: Index { items.endIndex }
        subscript(position: Index) -> T { items[position] }
        func index(after i: Index) -> Index { items.index(after: i) }
      }
      
      let collection = StringCollection(["hello", "world"])
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: collection,
        variableName: "testStrings"
      )
      
      #expect(code.contains("StringCollection<String>"))
      #expect(code.contains("hello"))
      #expect(code.contains("world"))
    }
    
    /// Test rendering empty generic collection
    @Test func emptyGenericCollection() throws {
      struct EmptyWrapper<T>: Collection {
        let data: [T]
        
        init() {
          self.data = []
        }
        
        typealias Index = Array<T>.Index
        var startIndex: Index { data.startIndex }
        var endIndex: Index { data.endIndex }
        subscript(position: Index) -> T { data[position] }
        func index(after i: Index) -> Index { data.index(after: i) }
      }
      
      let wrapper = EmptyWrapper<Int>()
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: wrapper,
        variableName: "emptyWrapper"
      )
      
      #expect(code.contains("EmptyWrapper<Int>"))
      #expect(code.contains("[]"))
    }
    
    // MARK: - Complex Generic Collection Tests
    
    /// Test rendering a generic collection with nested structs
    @Test func genericCollectionWithNestedStructs() throws {
      struct Person {
        let name: String
        let age: Int
      }
      
      struct PersonCollection<T>: Collection {
        let people: [T]
        
        init(_ people: [T]) {
          self.people = people
        }
        
        typealias Index = Array<T>.Index
        var startIndex: Index { people.startIndex }
        var endIndex: Index { people.endIndex }
        subscript(position: Index) -> T { people[position] }
        func index(after i: Index) -> Index { people.index(after: i) }
      }
      
      let collection = PersonCollection([
        Person(name: "Alice", age: 30),
        Person(name: "Bob", age: 25)
      ])
      
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: collection,
        variableName: "people"
      )
      
      #expect(code.contains("PersonCollection<Person>"))
      #expect(code.contains("Alice"))
      #expect(code.contains("Bob"))
      #expect(code.contains("30"))
      #expect(code.contains("25"))
    }
    
    /// Test rendering a generic collection with multiple type parameters
    @Test func multipleGenericParameters() throws {
      struct Pair<A, B> {
        let first: A
        let second: B
      }
      
      struct PairCollection<T, U>: Collection {
        let pairs: [Pair<T, U>]
        
        init(_ pairs: [Pair<T, U>]) {
          self.pairs = pairs
        }
        
        typealias Index = Array<Pair<T, U>>.Index
        var startIndex: Index { pairs.startIndex }
        var endIndex: Index { pairs.endIndex }
        subscript(position: Index) -> Pair<T, U> { pairs[position] }
        func index(after i: Index) -> Index { pairs.index(after: i) }
      }
      
      let collection = PairCollection([
        Pair(first: "one", second: 1),
        Pair(first: "two", second: 2)
      ])
      
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: collection,
        variableName: "pairs"
      )
      
      // Should handle the complex generic type
      #expect(code.contains("PairCollection"))
      #expect(code.contains("one"))
      #expect(code.contains("two"))
    }
    
    // MARK: - Edge Cases
    
    /// Test that regular arrays still work correctly
    @Test func regularArrayStillWorks() throws {
      let array = [1, 2, 3, 4, 5]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: array,
        variableName: "regularArray"
      )
      
      #expect(code.contains("[1, 2, 3, 4, 5]"))
    }
    
    /// Test that regular dictionaries still work correctly
    @Test func regularDictionaryStillWorks() throws {
      let dict = ["key": "value"]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: dict,
        variableName: "regularDict"
      )
      
      #expect(code.contains("key"))
      #expect(code.contains("value"))
    }
    
    /// Test that regular sets still work correctly
    @Test func regularSetStillWorks() throws {
      let set = Set([1, 2, 3])
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "regularSet"
      )
      
      #expect(code.contains("Set"))
    }
  }
}
