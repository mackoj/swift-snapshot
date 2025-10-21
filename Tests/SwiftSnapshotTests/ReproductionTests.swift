import InlineSnapshotTesting
import Testing

@testable import SwiftSnapshotCore

extension SnapshotTests {
  @Suite struct ReproductionTests {
    init() {
      // Reset configuration between tests
      SwiftSnapshotConfig.resetToLibraryDefaults()
    }

    @Test func testStringInStruct() throws {
      struct AddReviewViewModel {
        let productId: String
        let reviewsLegalNoticeUrl: URL?
      }

      let viewModel = AddReviewViewModel(
        productId: "ig_169380 ~ dm_8402040 ~ sku_0cebe88a - 32e1 - 49df - a17e - 150bb155f0fc",
        reviewsLegalNoticeUrl: URL(string: "https://reviews.decathlon.com/fr_FR/review/terms")
      )

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: viewModel,
        variableName: "testViewModel"
      )

      print("Generated code:")
      print(code)
      
      // This should compile without errors
      // The productId should be a string literal with quotes
      // The URL should be properly initialized
    }
    
    @Test func testComplexNestedStruct() throws {
      // Create a more complex structure that might trigger the issue
      struct ReviewField {
        let id: String
        let title: String
        let value: String
      }
      
      struct AddReviewViewModel {
        let productId: String
        let reviewsLegalNoticeUrl: URL?
        let isPostingReview: Bool
        let shouldDismissView: Bool
        let fields: [ReviewField]
      }

      let viewModel = AddReviewViewModel(
        productId: "ig_169380 ~ dm_8402040 ~ sku_0cebe88a - 32e1 - 49df - a17e - 150bb155f0fc",
        reviewsLegalNoticeUrl: URL(string: "https://reviews.decathlon.com/fr_FR/review/terms"),
        isPostingReview: false,
        shouldDismissView: false,
        fields: [
          ReviewField(id: "0", title: "Lorem ipsum", value: ""),
          ReviewField(id: "1", title: "Lorem ipsum", value: ""),
          ReviewField(id: "2", title: "Lorem ipsum", value: "")
        ]
      )

      let code = try SwiftSnapshotRuntime.generateSwiftCode(
        instance: viewModel,
        variableName: "ig_169380_dm_8402040_sku_0cebe88a_32e1_49df_a17e_150bb155f0fc"
      )

      print("\n\nGenerated code for complex struct:")
      print(code)
      print("\n\n")
      
      // Verify that the generated code has proper syntax structure
      // Check for key elements:
      // 1. String values should be in quotes
      #expect(code.contains("productId: \"ig_169380"))
      
      // 2. URL should be properly initialized
      #expect(code.contains("URL(string: \"https://reviews.decathlon.com"))
      
      // 3. All labeled arguments should have commas (except the last one before closing paren)
      // Count commas - should have at least 4 (for productId, reviewsLegalNoticeUrl, isPostingReview, shouldDismissView)
      let commaCount = code.filter { $0 == "," }.count
      #expect(commaCount >= 4)
    }
  }
}
