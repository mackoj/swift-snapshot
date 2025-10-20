import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshotCore

extension SnapshotTests {
  @Suite struct PropertyWrapperTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    // MARK: - Property Wrapper Tests

    @Test func simplePropertyWrapper() throws {
      @propertyWrapper
      struct Uppercase {
        private var value: String = ""

        var wrappedValue: String {
          get { value }
          set { value = newValue.uppercased() }
        }

        init(wrappedValue: String) {
          self.wrappedValue = wrappedValue
        }
      }

      struct User {
        @Uppercase var name: String
        var age: Int
      }

      let user = User(name: "alice", age: 25)

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: user,
        variableName: "testUser"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension User { static let testUser: User = User(name: "ALICE", age: 25) }

        """
      }
    }

    @Test func multiplePropertyWrappers() throws {
      @propertyWrapper
      struct Lowercase {
        private var value: String = ""

        var wrappedValue: String {
          get { value }
          set { value = newValue.lowercased() }
        }

        init(wrappedValue: String) {
          self.wrappedValue = wrappedValue
        }
      }

      @propertyWrapper
      struct Clamped {
        private var value: Int

        var wrappedValue: Int {
          get { value }
          set { value = newValue }
        }

        init(wrappedValue: Int) {
          self.value = wrappedValue
        }
      }

      struct GameState {
        @Lowercase var playerName: String
        @Clamped var health: Int
        var score: Int
      }

      let state = GameState(playerName: "WARRIOR", health: 75, score: 1000)

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: state,
        variableName: "testState"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension GameState {
            static let testState: GameState = GameState(playerName: "warrior", health: 75, score: 1000)
        }

        """
      }
    }

    @Test func propertyWrapperWithComplexType() throws {
      @propertyWrapper
      struct Validated<T> {
        private var value: T

        var wrappedValue: T {
          get { value }
          set { value = newValue }
        }

        init(wrappedValue: T) {
          self.value = wrappedValue
        }
      }

      struct Address {
        let street: String
        let city: String
      }

      struct Person {
        @Validated var name: String
        @Validated var address: Address
        var age: Int
      }

      let person = Person(
        name: "John",
        address: Address(street: "123 Main St", city: "Springfield"),
        age: 30
      )

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: person,
        variableName: "testPerson"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension Person {
            static let testPerson: Person = Person(
                name: "John",
                address: Address(street: "123 Main St", city: "Springfield"),
                age: 30
            )
        }

        """
      }
    }

    @Test func mixedPropertiesWithAndWithoutWrappers() throws {
      @propertyWrapper
      struct Trimmed {
        private var value: String

        var wrappedValue: String {
          get { value }
          set { value = newValue.trimmingCharacters(in: .whitespaces) }
        }

        init(wrappedValue: String) {
          self.value = wrappedValue.trimmingCharacters(in: .whitespaces)
        }
      }

      struct FormData {
        var id: String
        @Trimmed var username: String
        var isActive: Bool
        @Trimmed var email: String
      }

      let data = FormData(
        id: "123",
        username: "  john_doe  ",
        isActive: true,
        email: "  test@example.com  "
      )

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: data,
        variableName: "testFormData"
      )

      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension FormData {
            static let testFormData: FormData = FormData(
                id: "123",
                username: "john_doe",
                isActive: true,
                email: "test@example.com"
            )
        }

        """
      }
    }

    @Test func propertyWrapperWithUnsafePointer() throws {
      // This test simulates Combine's @Published which uses UnsafeMutablePointer internally
      @propertyWrapper
      struct MockPublished<Value> {
        // Simulating @Published's internal storage with an unsafe pointer
        private var storage: UnsafeMutablePointer<Value>

        var wrappedValue: Value {
          get { storage.pointee }
          set { storage.pointee = newValue }
        }

        init(wrappedValue: Value) {
          storage = UnsafeMutablePointer<Value>.allocate(capacity: 1)
          storage.initialize(to: wrappedValue)
        }
      }

      struct ViewModel {
        @MockPublished var isLoading: Bool
        var title: String
      }

      let viewModel = ViewModel(isLoading: false, title: "Test")

      // This should not throw "Unsupported type: UnsafeMutablePointer"
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: viewModel,
        variableName: "testViewModel"
      )

      // The unsafe pointer should be rendered as nil
      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension ViewModel {
            static let testViewModel: ViewModel = ViewModel(isLoading: nil, title: "Test")
        }

        """
      }
    }
  }
}
