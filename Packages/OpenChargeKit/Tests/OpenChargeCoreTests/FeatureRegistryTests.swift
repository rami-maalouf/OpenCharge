@testable import OpenChargeCore
import Testing

@Suite("Feature registry")
struct FeatureRegistryTests {
    @Test
    func ordersDescriptorsByStableIdentifier() throws {
        let foundationID = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let finderID = try #require(FeatureID(rawValue: "finder.copy-path"))
        let registry = FeatureRegistry(factories: [
            factory(id: foundationID),
            factory(id: finderID)
        ])

        #expect(registry.descriptors.map(\.id) == [finderID, foundationID])
        #expect(registry.issues.isEmpty)
    }

    @Test
    func preservesHealthyFeaturesWhenFactoryFails() throws {
        let healthyID = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let failedID = try #require(FeatureID(rawValue: "foundation.capture-text"))
        let registry = FeatureRegistry(factories: [
            FeatureFactory(id: failedID) {
                throw FactoryFailure.expected
            },
            factory(id: healthyID)
        ])

        #expect(registry.descriptors.map(\.id) == [healthyID])
        #expect(registry.issues == [.factoryFailed(id: failedID)])
    }

    @Test
    func rejectsEveryFactoryWithDuplicateIdentifier() throws {
        let duplicateID = try #require(FeatureID(rawValue: "finder.copy-path"))
        let registry = FeatureRegistry(factories: [
            factory(id: duplicateID, titleKey: "feature.copyPath.first"),
            factory(id: duplicateID, titleKey: "feature.copyPath.second")
        ])

        #expect(registry.descriptors.isEmpty)
        #expect(registry.issues == [.duplicateIdentifier(id: duplicateID)])
    }

    @Test
    func rejectsDescriptorThatDoesNotMatchDeclaredIdentifier() throws {
        let declaredID = try #require(FeatureID(rawValue: "finder.copy-path"))
        let returnedID = try #require(FeatureID(rawValue: "finder.open-terminal"))
        let registry = FeatureRegistry(factories: [
            FeatureFactory(id: declaredID) {
                descriptor(id: returnedID, titleKey: "feature.openTerminal.title")
            }
        ])

        #expect(registry.descriptors.isEmpty)
        #expect(
            registry.issues == [
                .identifierMismatch(expected: declaredID, actual: returnedID)
            ]
        )
    }
}

private enum FactoryFailure: Error {
    case expected
}

private func factory(
    id: FeatureID,
    titleKey: String = "feature.fixture.title"
) -> FeatureFactory {
    FeatureFactory(id: id) {
        descriptor(id: id, titleKey: titleKey)
    }
}

private func descriptor(id: FeatureID, titleKey: String) -> FeatureDescriptor {
    FeatureDescriptor(
        id: id,
        category: .foundation,
        titleKey: titleKey,
        descriptionKey: "feature.fixture.description",
        supportsGlobalShortcut: false,
        supportsAppIntent: false
    )
}
