import Testing

@testable import SwiftSnapshotCore

/// US-6 – Result<Success, Failure> must render as .success(…) or .failure(…).
extension SnapshotTests {
  @Suite("US-6 Result Type") struct ResultTypeTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    enum AppError: Error, CustomStringConvertible {
      case notFound
      case unauthorized
      var description: String {
        switch self {
        case .notFound: return "notFound"
        case .unauthorized: return "unauthorized"
        }
      }
    }

    @Test("Result.success renders as .success(value)")
    func successResultRendersCorrectly() throws {
      let result: Result<String, AppError> = .success("ok")
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: result,
        variableName: "testSuccess"
      )
      #expect(code.contains(".success("))
      // Must NOT produce internal storage representation
      #expect(!code.contains("_storage"))
      #expect(!code.contains("ResultBox"))
    }

    @Test("Result.failure renders as .failure(error)")
    func failureResultRendersCorrectly() throws {
      let result: Result<String, AppError> = .failure(.notFound)
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: result,
        variableName: "testFailure"
      )
      #expect(code.contains(".failure("))
      #expect(!code.contains("_storage"))
    }

    @Test("Result<Int, Error>.success renders the success value")
    func successWithIntValue() throws {
      let result: Result<Int, Error> = .success(42)
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: result,
        variableName: "testIntSuccess"
      )
      #expect(code.contains(".success("))
      #expect(code.contains("42"))
    }

    @Test("Result as a struct property renders correctly")
    func resultInsideStruct() throws {
      struct Response {
        let status: Int
        let body: Result<String, AppError>
      }
      let r = Response(status: 200, body: .success("hello"))
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: r,
        variableName: "testResponse"
      )
      #expect(code.contains(".success("))
      #expect(code.contains("200"))
    }
  }
}
