import Testing

@testable import SwiftSnapshotCore

/// US-5 – Set ordering must be stable across runs.
/// Elements are sorted by their rendered expression string rather than String(describing:),
/// which is more robust against Swift version changes for complex types.
extension SnapshotTests {
  @Suite("US-5 Set Determinism") struct SetDeterminismTests {
    init() {
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    @Test("Set<String> always produces the same output for the same input")
    func setOfStringsIsStable() throws {
      let set: Set<String> = ["banana", "apple", "cherry"]

      let code1 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testSet"
      )
      let code2 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testSet"
      )

      // Two renders of the same set must produce identical code
      #expect(code1 == code2)

      // Strings should appear in lexicographic order of their rendered representation
      let appleIdx = code1.range(of: "\"apple\"")
      let bananaIdx = code1.range(of: "\"banana\"")
      let cherryIdx = code1.range(of: "\"cherry\"")
      if let a = appleIdx, let b = bananaIdx, let c = cherryIdx {
        #expect(a.lowerBound < b.lowerBound)
        #expect(b.lowerBound < c.lowerBound)
      }
    }

    @Test("Set<UUID> produces the same output across two calls")
    func setOfUUIDsIsStableAcrossCalls() throws {
      let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
      let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
      let set: Set<UUID> = [id1, id2]

      let code1 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testUUIDs"
      )
      let code2 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testUUIDs"
      )

      #expect(code1 == code2)
    }

    @Test("Empty set renders without crashing")
    func emptySetRenders() throws {
      let set = Set<String>()
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "emptySet"
      )
      #expect(code.contains("Set("))
    }

    @Test("Set<Int> produces consistent output")
    func setOfIntsIsConsistent() throws {
      let set: Set<Int> = [3, 1, 4, 1, 5, 9, 2, 6]

      let code1 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testInts"
      )
      let code2 = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: set,
        variableName: "testInts"
      )

      #expect(code1 == code2)
    }
  }
}
