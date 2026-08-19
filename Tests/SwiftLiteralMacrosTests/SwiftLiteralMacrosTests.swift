import MacroTesting
import Testing
import SwiftLiteralMacros

extension LiteralTests {
  @Suite(
    .macros(
      [
        "SwiftLiteral": SwiftLiteralMacro.self,
        "LiteralIgnore": LiteralIgnoreMacro.self,
        "LiteralRename": LiteralRenameMacro.self,
        "LiteralRedact": LiteralRedactMacro.self,
      ]
    )
  )
  struct SwiftLiteralMacrosTests {
    @Test func basicStruct() {
    assertMacro {
      """
      @SwiftLiteral
      struct Product {
        let id: String
        let name: String
      }
      """
    } expansion: {
      #"""
      struct Product {
        let id: String
        let name: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "name", renamed: nil, redaction: nil, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "name", value: self.name)
          ]
        }
      }

      extension Product: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "product",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func structWithIgnore() {
    assertMacro {
      """
      @SwiftLiteral
      struct User {
        let id: String
        @LiteralIgnore
        let cache: [String: Any]
      }
      """
    } expansion: {
      #"""
      struct User {
        let id: String
        let cache: [String: Any]

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "cache", renamed: nil, redaction: nil, ignored: true)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id)
          ]
        }
      }

      extension User: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "user",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func structWithRename() {
    assertMacro {
      """
      @SwiftLiteral
      struct Product {
        let id: String
        @LiteralRename("displayName")
        let name: String
      }
      """
    } expansion: {
      #"""
      struct Product {
        let id: String
        let name: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "name", renamed: "displayName", redaction: nil, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "displayName", value: self.name)
          ]
        }
      }

      extension Product: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "product",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func structWithRedactMask() {
    assertMacro {
      """
      @SwiftLiteral
      struct User {
        let id: String
        @LiteralRedact(.mask("SECRET"))
        let apiKey: String
      }
      """
    } expansion: {
      #"""
      struct User {
        let id: String
        let apiKey: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "apiKey", renamed: nil, redaction: .mask("SECRET"), ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "apiKey", value: "SECRET")
          ]
        }
      }

      extension User: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "user",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func structWithRedactHash() {
    assertMacro {
      """
      @SwiftLiteral
      struct Account {
        let id: String
        @LiteralRedact(.hash)
        let password: String
      }
      """
    } expansion: {
      #"""
      struct Account {
        let id: String
        let password: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "password", renamed: nil, redaction: .hash, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "password", value: "<hashed>")
          ]
        }
      }

      extension Account: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "account",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func structWithRedactDefault() {
    assertMacro {
      """
      @SwiftLiteral
      struct Config {
        let id: String
        @LiteralRedact
        let token: String
      }
      """
    } expansion: {
      #"""
      struct Config {
        let id: String
        let token: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "token", renamed: nil, redaction: .mask("•••"), ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "token", value: "•••")
          ]
        }
      }

      extension Config: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "config",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func simpleEnum() {
    assertMacro {
      """
      @SwiftLiteral
      enum Status {
        case active
        case inactive
        case pending
      }
      """
    } expansion: {
      """
      enum Status {
        case active
        case inactive
        case pending

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [

          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          []
        }
      }

      extension Status: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "status",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """
    }
  }

    @Test func folderParameter() {
    assertMacro {
      """
      @SwiftLiteral(folder: "Fixtures/Products")
      struct Product {
        let id: String
      }
      """
    } expansion: {
      #"""
      struct Product {
        let id: String

        internal static var __swiftLiteral_folder: String? {
          "Fixtures/Products"
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id)
          ]
        }
      }

      extension Product: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "product",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
    }
  }

    @Test func structLikeSyncUpFormModel() {
    assertMacro {
      """
      @SwiftLiteral
      struct SyncUpFormModel {
        let focus: String
        let syncUp: String
        let uuid: String
      }
      """
    } expansion: {
      #"""
      struct SyncUpFormModel {
        let focus: String
        let syncUp: String
        let uuid: String

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "focus", renamed: nil, redaction: nil, ignored: false),
            .init(original: "syncUp", renamed: nil, redaction: nil, ignored: false),
            .init(original: "uuid", renamed: nil, redaction: nil, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "focus", value: self.focus), LiteralField(label: "syncUp", value: self.syncUp), LiteralField(label: "uuid", value: self.uuid)
          ]
        }
      }

      extension SyncUpFormModel: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "syncUpFormModel",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }

    @Test func genericStruct() {
    assertMacro {
      """
      @SwiftLiteral
      struct User<T: Codable> {
        let id: Int
        let name: String
        let some: [T]
      }
      """
    } expansion: {
      #"""
      struct User<T: Codable> {
        let id: Int
        let name: String
        let some: [T]

        internal static var __swiftLiteral_folder: String? {
          nil
        }

        internal struct __SwiftLiteral_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftLiteral_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftLiteral_Redaction {
          case mask(String)
          case hash
        }

        internal static var __swiftLiteral_properties: [__SwiftLiteral_PropertyMetadata] {
          [
            .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "name", renamed: nil, redaction: nil, ignored: false),
            .init(original: "some", renamed: nil, redaction: nil, ignored: false)
          ]
        }

        public func __swiftLiteral_fields() -> [LiteralField] {
          [
            LiteralField(label: "id", value: self.id), LiteralField(label: "name", value: self.name), LiteralField(label: "some", value: self.some)
          ]
        }
      }

      extension User: LiteralFields {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        @discardableResult
        public func writeLiteral(
          named name: String? = nil,
          file: String? = nil,
          allowOverwrite: Bool = true,
          header: String? = nil,
          context: String? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          try Literal.write(
            self,
            named: name ?? "user",
            file: file,
            directory: Self.__swiftLiteral_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }
}
