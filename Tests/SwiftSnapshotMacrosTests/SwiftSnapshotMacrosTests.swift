import MacroTesting
import Testing
import SwiftSnapshotMacros

extension SnapshotTests {
  @Suite(
    .macros(
      [
        "SwiftSnapshot": SwiftSnapshotMacro.self,
        "SnapshotIgnore": SnapshotIgnoreMacro.self,
        "SnapshotRename": SnapshotRenameMacro.self,
        "SnapshotRedact": SnapshotRedactMacro.self,
      ]
    )
  )
  struct SwiftSnapshotMacrosTests {
    @Test func basicStruct() {
    assertMacro {
      """
      @SwiftSnapshot
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

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "name", renamed: nil, redaction: nil, ignored: false)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: Product) -> String {
          return "Product(id: \(instance.id), name: \(instance.name))"
        }
      }

      extension Product: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "product"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot
      struct User {
        let id: String
        @SnapshotIgnore
        let cache: [String: Any]
      }
      """
    } expansion: {
      #"""
      struct User {
        let id: String
        let cache: [String: Any]

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "cache", renamed: nil, redaction: nil, ignored: true)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: User) -> String {
          return "User(id: \(instance.id))"
        }
      }

      extension User: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "user"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot
      struct Product {
        let id: String
        @SnapshotRename("displayName")
        let name: String
      }
      """
    } expansion: {
      #"""
      struct Product {
        let id: String
        let name: String

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "name", renamed: "displayName", redaction: nil, ignored: false)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: Product) -> String {
          return "Product(id: \(instance.id), displayName: \(instance.name))"
        }
      }

      extension Product: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "product"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot
      struct User {
        let id: String
        @SnapshotRedact(mask: "SECRET")
        let apiKey: String
      }
      """
    } expansion: {
      #"""
      struct User {
        let id: String
        let apiKey: String

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "id", renamed: nil, redaction: nil, ignored: false),
            .init(original: "apiKey", renamed: nil, redaction: .mask("SECRET"), ignored: false)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: User) -> String {
          return "User(id: \(instance.id), apiKey: \"SECRET\")"
        }
      }

      extension User: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "user"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot
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

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [

        ]

        internal static func __swiftSnapshot_makeExpr(from instance: Status) -> String {
          switch instance {
          case .active:
              return ".active"
              case .inactive:
              return ".inactive"
              case .pending:
              return ".pending"
          }
        }
      }

      extension Status: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "status"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot(folder: "Fixtures/Products")
      struct Product {
        let id: String
      }
      """
    } expansion: {
      #"""
      struct Product {
        let id: String

        internal static let __swiftSnapshot_folder: String? = "Fixtures/Products"

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "id", renamed: nil, redaction: nil, ignored: false)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: Product) -> String {
          return "Product(id: \(instance.id))"
        }
      }

      extension Product: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "product"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
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
      @SwiftSnapshot
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

        internal static let __swiftSnapshot_folder: String? = nil

        internal struct __SwiftSnapshot_PropertyMetadata {
          let original: String
          let renamed: String?
          let redaction: __SwiftSnapshot_Redaction?
          let ignored: Bool
        }

        internal enum __SwiftSnapshot_Redaction {
          case mask(String)
          case hash
        }

        internal static let __swiftSnapshot_properties: [__SwiftSnapshot_PropertyMetadata] = [
          .init(original: "focus", renamed: nil, redaction: nil, ignored: false),
            .init(original: "syncUp", renamed: nil, redaction: nil, ignored: false),
            .init(original: "uuid", renamed: nil, redaction: nil, ignored: false)
        ]

        internal static func __swiftSnapshot_makeExpr(from instance: SyncUpFormModel) -> String {
          return "SyncUpFormModel(focus: \(instance.focus), syncUp: \(instance.syncUp), uuid: \(instance.uuid))"
        }
      }

      extension SyncUpFormModel: SwiftSnapshotExportable {
        /// Export this instance as a Swift snapshot fixture.
        ///
        /// **Debug Only**: This method only operates in DEBUG builds. In release builds,
        /// it returns a placeholder URL and performs no file I/O.
        public func exportSnapshot(
          variableName: String? = nil,
          testName: String? = nil,
          header: String? = nil,
          context: String? = nil,
          allowOverwrite: Bool = true,
          line: UInt = #line,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath
        ) throws -> URL {
          let defaultVarName = "syncUpFormModel"
          let effectiveVarName = variableName ?? defaultVarName

          return try SwiftSnapshotRuntime.export(
            instance: self,
            variableName: effectiveVarName,
            fileName: nil as String?,
            outputBasePath: Self.__swiftSnapshot_folder,
            allowOverwrite: allowOverwrite,
            header: header,
            context: context,
            testName: testName,
            line: line,
            fileID: fileID,
            filePath: filePath
          )
        }
      }
      """#
    }
  }
}
