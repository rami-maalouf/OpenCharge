@testable import OpenCharge
import OpenChargeCore
import XCTest

final class MenuModelTests: XCTestCase {
    @MainActor
    func testGroupsEnabledFeaturesInDeterministicCategoryOrder() throws {
        let finderID = try XCTUnwrap(FeatureID(rawValue: "finder.copy-path"))
        let foundationID = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        let registry = FeatureRegistry(factories: [
            factory(id: foundationID, category: .foundation),
            factory(id: finderID, category: .finder)
        ])
        var settings = SettingsSchema.default
        settings.setFeature(foundationID, enabled: true)
        settings.setFeature(finderID, enabled: true)

        let model = MenuModel(registry: registry, settings: settings, loadState: .loaded)

        XCTAssertEqual(model.featureSections.map(\.category), [.finder, .foundation])
        XCTAssertEqual(model.featureSections.flatMap(\.features).map(\.id), [finderID, foundationID])
    }

    @MainActor
    func testOmitsDisabledFeatures() throws {
        let id = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        let registry = FeatureRegistry(factories: [factory(id: id, category: .foundation)])

        let model = MenuModel(registry: registry, settings: .default, loadState: .loaded)

        XCTAssertTrue(model.featureSections.isEmpty)
    }

    @MainActor
    func testFactoryFailureDoesNotHideHealthyFeatureOrStaticItems() throws {
        let healthyID = try XCTUnwrap(FeatureID(rawValue: "finder.copy-path"))
        let failedID = try XCTUnwrap(FeatureID(rawValue: "finder.open-terminal"))
        let registry = FeatureRegistry(factories: [
            FeatureFactory(id: failedID) { throw FactoryFailure.expected },
            factory(id: healthyID, category: .finder)
        ])
        var settings = SettingsSchema.default
        settings.setFeature(healthyID, enabled: true)

        let model = MenuModel(registry: registry, settings: settings, loadState: .loaded)

        XCTAssertEqual(model.featureSections.flatMap(\.features).map(\.id), [healthyID])
        XCTAssertEqual(model.health, .degraded(issueCount: 1))
        XCTAssertEqual(model.staticItems, [.settings, .permissions, .about, .quit])
    }

    @MainActor
    func testSettingsFailureIsVisibleWithoutRemovingStaticItems() {
        let model = MenuModel(
            registry: FeatureRegistry(factories: []),
            settings: .default,
            loadState: .failed
        )

        XCTAssertEqual(model.health, .settingsUnavailable)
        XCTAssertEqual(model.staticItems, MenuStaticItem.allCases)
    }

    @MainActor
    func testAppliesFavoriteVisibilityAndCustomOrder() throws {
        let keepAwakeID = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        let captureTextID = try XCTUnwrap(FeatureID(rawValue: "foundation.capture-text"))
        let clearClipboardID = try XCTUnwrap(
            FeatureID(rawValue: "foundation.clear-clipboard")
        )
        let registry = FeatureRegistry(factories: [
            factory(id: keepAwakeID, category: .foundation),
            factory(id: captureTextID, category: .foundation),
            factory(id: clearClipboardID, category: .foundation)
        ])
        var settings = SettingsSchema.default
        for id in [keepAwakeID, captureTextID, clearClipboardID] {
            settings.setFeature(id, enabled: true)
        }
        let preferences = MenuPreferences(
            favoriteFeatureIDs: [clearClipboardID],
            hiddenFeatureIDs: [captureTextID],
            orderedFeatureIDs: [clearClipboardID, captureTextID, keepAwakeID],
            iconChoice: .bolt,
            shortcutReferences: [:]
        )

        let model = MenuModel(
            registry: registry,
            settings: settings,
            preferences: preferences,
            loadState: .loaded
        )

        XCTAssertEqual(model.favoriteFeatures.map(\.id), [clearClipboardID])
        XCTAssertEqual(model.featureSections.flatMap(\.features).map(\.id), [keepAwakeID])
    }
}

private enum FactoryFailure: Error {
    case expected
}

private func factory(id: FeatureID, category: FeatureCategory) -> FeatureFactory {
    FeatureFactory(id: id) {
        FeatureDescriptor(
            id: id,
            category: category,
            titleKey: "feature.fixture.title",
            descriptionKey: "feature.fixture.description",
            supportsGlobalShortcut: false,
            supportsAppIntent: false
        )
    }
}
