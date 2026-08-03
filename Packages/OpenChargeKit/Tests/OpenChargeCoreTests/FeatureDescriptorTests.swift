import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Feature descriptor")
struct FeatureDescriptorTests {
    @Test
    func rejectsEmptyAndMalformedIdentifiers() {
        #expect(FeatureID(rawValue: "") == nil)
        #expect(FeatureID(rawValue: "   ") == nil)
        #expect(FeatureID(rawValue: "Keep Awake") == nil)
        #expect(FeatureID(rawValue: "foundation.keep_awake") == nil)
        #expect(FeatureID(rawValue: ".foundation.keep-awake") == nil)
    }

    @Test
    func acceptsStableNamespacedIdentifier() throws {
        let id = try #require(FeatureID(rawValue: "foundation.keep-awake"))

        #expect(id.rawValue == "foundation.keep-awake")
        #expect(id.description == "foundation.keep-awake")
    }

    @Test
    func descriptorRoundTripsThroughJSON() throws {
        let descriptor = try FeatureDescriptor(
            id: #require(FeatureID(rawValue: "finder.copy-path")),
            category: .finder,
            titleKey: "feature.copyPath.title",
            descriptionKey: "feature.copyPath.description",
            supportsGlobalShortcut: true,
            supportsAppIntent: false
        )

        let encoded = try JSONEncoder().encode(descriptor)
        let decoded = try JSONDecoder().decode(FeatureDescriptor.self, from: encoded)

        #expect(decoded == descriptor)
    }

    @Test
    func identifiersSortByStableRawValue() throws {
        let finder = try #require(FeatureID(rawValue: "finder.copy-path"))
        let foundation = try #require(FeatureID(rawValue: "foundation.keep-awake"))

        #expect([foundation, finder].sorted() == [finder, foundation])
    }
}
