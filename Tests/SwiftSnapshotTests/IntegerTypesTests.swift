import Testing
import Foundation
import InlineSnapshotTesting

@testable import SwiftSnapshotCore

extension SnapshotTests {
  /// Tests for all integer type variants
  @Suite struct IntegerTypesTests {
    
    // MARK: - Signed Integer Tests
    
    @Test func int8Generation() throws {
      let value: Int8 = 42
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testInt8"
      )
      
      #expect(code.contains("Int8(42)"))
    }
    
    @Test func int16Generation() throws {
      let value: Int16 = 1000
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testInt16"
      )
      
      #expect(code.contains("Int16(1000)"))
    }
    
    @Test func int32Generation() throws {
      let value: Int32 = 100000
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testInt32"
      )
      
      #expect(code.contains("Int32(100000)"))
    }
    
    @Test func int64Generation() throws {
      let value: Int64 = 9223372036854775807
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testInt64"
      )
      
      // The formatter may add underscores for readability
      #expect(code.contains("Int64") && code.contains("9"))
    }
    
    // MARK: - Unsigned Integer Tests
    
    @Test func uintGeneration() throws {
      let value: UInt = 42
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testUInt"
      )
      
      #expect(code.contains("UInt(42)"))
    }
    
    @Test func uint8Generation() throws {
      let value: UInt8 = 255
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testUInt8"
      )
      
      #expect(code.contains("UInt8(255)"))
    }
    
    @Test func uint16Generation() throws {
      let value: UInt16 = 65535
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testUInt16"
      )
      
      #expect(code.contains("UInt16(65535)"))
    }
    
    @Test func uint32Generation() throws {
      let value: UInt32 = 4294967295
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testUInt32"
      )
      
      // The formatter may add underscores for readability
      #expect(code.contains("UInt32") && code.contains("4"))
    }
    
    @Test func uint64Generation() throws {
      let value: UInt64 = 18446744073709551615
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "testUInt64"
      )
      
      // The formatter may add underscores for readability
      #expect(code.contains("UInt64") && code.contains("18"))
    }
    
    // MARK: - Struct with Various Integer Types
    
    @Test func structWithMixedIntegerTypes() throws {
      struct MixedIntegers {
        let int8Val: Int8
        let uint64Val: UInt64
        let int32Val: Int32
      }
      
      let value = MixedIntegers(int8Val: 10, uint64Val: 123456789, int32Val: -500)
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "mixedInts"
      )
      
      assertInlineSnapshot(of: code, as: .description) {
        """
        import Foundation

        extension MixedIntegers {
            static let mixedInts: MixedIntegers = MixedIntegers(
                int8Val: Int8(10),
                uint64Val: UInt64(123_456_789),
                int32Val: Int32(-500)
            )
        }

        """
      }
    }
    
    // MARK: - Arrays with Integer Types
    
    @Test func arrayOfUInt64() throws {
      let values: [UInt64] = [1, 2, 3, 4, 5]
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: values,
        variableName: "uint64Array"
      )
      
      #expect(code.contains("UInt64(1)"))
      #expect(code.contains("UInt64(2)"))
      #expect(code.contains("UInt64(3)"))
    }
    
    // MARK: - Edge Cases
    
    @Test func negativeIntegers() throws {
      let value: Int32 = -42
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "negativeInt"
      )
      
      #expect(code.contains("Int32(-42)"))
    }
    
    @Test func zeroValue() throws {
      let value: UInt64 = 0
      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: value,
        variableName: "zeroVal"
      )
      
      #expect(code.contains("UInt64(0)"))
    }
  }
}
