@testable import OpenCharge
import OpenChargeCore
import OpenChargeSystem
import XCTest

final class MenuSettingsModelTests: XCTestCase {
    @MainActor
    func testPersistsFavoritesVisibilityOrderAndIconChoice() async throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let captureTextID = try featureID("foundation.capture-text")
        let registry = registry(ids: [keepAwakeID, captureTextID])
        let store = InMemorySettingsStore()
        let model = MenuSettingsModel(registry: registry, settingsStore: store)
        var publishedSettings: SettingsSchema?
        model.configure { publishedSettings = $0 }
        model.load(from: .default)

        await model.setFavorite(true, for: captureTextID)
        await model.setVisible(false, for: keepAwakeID)
        await model.move(captureTextID, direction: .down)
        await model.setIconChoice(.gauge)

        let storedSettings = await store.snapshot()
        let storedPreferences = MenuPreferences(settings: storedSettings)
        XCTAssertEqual(storedPreferences.favoriteFeatureIDs, [captureTextID])
        XCTAssertEqual(storedPreferences.hiddenFeatureIDs, [keepAwakeID])
        XCTAssertEqual(storedPreferences.orderedFeatureIDs, [keepAwakeID, captureTextID])
        XCTAssertEqual(storedPreferences.iconChoice, .gauge)
        XCTAssertEqual(publishedSettings, storedSettings)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor
    func testFailedSaveRollsBackOptimisticChange() async throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let model = MenuSettingsModel(
            registry: registry(ids: [keepAwakeID]),
            settingsStore: FailingMenuSettingsStore()
        )
        model.load(from: .default)

        await model.setFavorite(true, for: keepAwakeID)

        XCTAssertFalse(model.isFavorite(keepAwakeID))
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isSaving)
    }

    @MainActor
    func testLoadsAndSanitizesStalePreferences() throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let staleID = try featureID("foundation.removed")
        let model = MenuSettingsModel(
            registry: registry(ids: [keepAwakeID]),
            settingsStore: InMemorySettingsStore()
        )
        var settings = SettingsSchema.default
        MenuPreferences(
            favoriteFeatureIDs: [keepAwakeID, staleID],
            hiddenFeatureIDs: [staleID],
            orderedFeatureIDs: [staleID, keepAwakeID],
            iconChoice: .boltCircle,
            shortcutReferences: [:]
        ).write(to: &settings)

        model.load(from: settings)

        XCTAssertEqual(model.preferences.favoriteFeatureIDs, [keepAwakeID])
        XCTAssertTrue(model.preferences.hiddenFeatureIDs.isEmpty)
        XCTAssertEqual(model.preferences.orderedFeatureIDs, [keepAwakeID])
        XCTAssertEqual(model.preferences.iconChoice, .boltCircle)
    }

    private func featureID(_ rawValue: String) throws -> FeatureID {
        try XCTUnwrap(FeatureID(rawValue: rawValue))
    }

    private func registry(ids: [FeatureID]) -> FeatureRegistry {
        FeatureRegistry(factories: ids.map { id in
            FeatureFactory(id: id) {
                FeatureDescriptor(
                    id: id,
                    category: .foundation,
                    titleKey: id.rawValue,
                    descriptionKey: "feature.fixture.description",
                    supportsGlobalShortcut: true,
                    supportsAppIntent: true
                )
            }
        })
    }
}

private actor FailingMenuSettingsStore: SettingsStore {
    func snapshot() throws -> SettingsSchema {
        .default
    }

    func update(
        _: @Sendable (inout SettingsSchema) throws -> Void
    ) throws -> SettingsSchema {
        throw MenuSettingsTestFailure.expected
    }
}

private enum MenuSettingsTestFailure: Error {
    case expected
}
