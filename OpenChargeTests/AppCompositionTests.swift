@testable import OpenCharge
import OpenChargeCore
import OpenChargeSystem
import XCTest

final class AppCompositionTests: XCTestCase {
    @MainActor
    func testModelLoadsInjectedSettingsWithoutRealPreferences() async throws {
        let featureID = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        var settings = SettingsSchema.default
        settings.setFeature(featureID, enabled: true)
        let store: any SettingsStore = InMemorySettingsStore(initial: settings)
        let dependencies = AppDependencies(
            registry: FeatureRegistry(factories: []),
            settingsStore: store,
            hasPersistentSettings: false
        )
        let model = AppModel(dependencies: dependencies)

        await model.load()

        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertTrue(model.settings.isFeatureEnabled(featureID))
        XCTAssertFalse(model.hasPersistentSettings)
    }

    @MainActor
    func testSettingsFailureDoesNotPreventModelConstruction() async {
        let dependencies = AppDependencies(
            registry: FeatureRegistry(factories: []),
            settingsStore: FailingSettingsStore(),
            hasPersistentSettings: false
        )
        let model = AppModel(dependencies: dependencies)

        await model.load()

        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(model.settings, .default)
        XCTAssertTrue(model.registry.descriptors.isEmpty)
    }

    @MainActor
    func testPreviewDependenciesUseInMemorySettings() async {
        let model = AppModel(dependencies: .preview)

        await model.load()

        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertFalse(model.hasPersistentSettings)
    }
}

private actor FailingSettingsStore: SettingsStore {
    func snapshot() throws -> SettingsSchema {
        throw TestFailure.expected
    }

    func update(
        _: @Sendable (inout SettingsSchema) throws -> Void
    ) throws -> SettingsSchema {
        throw TestFailure.expected
    }
}

private enum TestFailure: Error {
    case expected
}
