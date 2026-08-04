import Foundation
import OpenChargeCore
@testable import OpenChargeFeatures
import Testing
import TestSupport

@Suite("Menu preferences")
struct MenuPreferencesTests {
    @Test
    func sanitizesStaleAndDuplicateStableIdentifiers() throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let copyPathID = try featureID("finder.copy-path")
        let staleID = try featureID("foundation.removed-action")
        let keepAwakeShortcutReference = try shortcutReference("shortcut.keep-awake")
        let registry = FeatureRegistry(factories: [
            factory(id: keepAwakeID, supportsGlobalShortcut: true),
            factory(id: copyPathID)
        ])
        let preferences = try MenuPreferences(
            favoriteFeatureIDs: [keepAwakeID, staleID],
            hiddenFeatureIDs: [copyPathID, staleID],
            orderedFeatureIDs: [staleID, copyPathID, keepAwakeID, copyPathID],
            iconChoice: .gauge,
            shortcutReferences: [
                keepAwakeID: keepAwakeShortcutReference,
                copyPathID: shortcutReference("shortcut.copy-path"),
                staleID: shortcutReference("shortcut.removed-action")
            ]
        )

        let sanitized = preferences.sanitized(for: registry.descriptors)

        #expect(sanitized.favoriteFeatureIDs == [keepAwakeID])
        #expect(sanitized.hiddenFeatureIDs == [copyPathID])
        #expect(sanitized.orderedFeatureIDs == [copyPathID, keepAwakeID])
        #expect(sanitized.iconChoice == .gauge)
        #expect(sanitized.shortcutReferences == [keepAwakeID: keepAwakeShortcutReference])
    }

    @Test
    func producesFavoritesThenDeterministicCategorySections() throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let captureTextID = try featureID("foundation.capture-text")
        let copyPathID = try featureID("finder.copy-path")
        let copyFilenameID = try featureID("finder.copy-filename")
        let registry = FeatureRegistry(factories: [
            factory(id: copyPathID, category: .finder),
            factory(id: captureTextID),
            factory(id: copyFilenameID, category: .finder),
            factory(id: keepAwakeID)
        ])
        var settings = SettingsSchema.default
        for item in [keepAwakeID, captureTextID, copyPathID, copyFilenameID] {
            settings.setFeature(item, enabled: true)
        }
        let preferences = MenuPreferences(
            favoriteFeatureIDs: [copyPathID, keepAwakeID],
            hiddenFeatureIDs: [],
            orderedFeatureIDs: [copyFilenameID, keepAwakeID, copyPathID],
            iconChoice: .boltCircle,
            shortcutReferences: [:]
        )

        let configuration = MenuConfiguration(
            registry: registry,
            settings: settings,
            preferences: preferences
        )

        #expect(configuration.favoriteFeatures.map(\.id) == [keepAwakeID, copyPathID])
        #expect(configuration.sections.map(\.category) == [.finder, .foundation])
        #expect(configuration.sections[0].features.map(\.id) == [copyFilenameID])
        #expect(configuration.sections[1].features.map(\.id) == [captureTextID])
        #expect(configuration.preferences.iconChoice == .boltCircle)
    }

    @Test
    func excludesDisabledAndHiddenFeaturesWithoutLosingValidPreferences() throws {
        let visibleID = try featureID("foundation.visible")
        let hiddenID = try featureID("foundation.hidden")
        let disabledID = try featureID("finder.disabled")
        let registry = FeatureRegistry(factories: [
            factory(id: disabledID, category: .finder),
            factory(id: hiddenID),
            factory(id: visibleID)
        ])
        var settings = SettingsSchema.default
        settings.setFeature(visibleID, enabled: true)
        settings.setFeature(hiddenID, enabled: true)
        let preferences = MenuPreferences(
            favoriteFeatureIDs: [disabledID],
            hiddenFeatureIDs: [hiddenID],
            orderedFeatureIDs: [disabledID, hiddenID, visibleID],
            iconChoice: .bolt,
            shortcutReferences: [:]
        )

        let configuration = MenuConfiguration(
            registry: registry,
            settings: settings,
            preferences: preferences
        )

        #expect(configuration.favoriteFeatures.isEmpty)
        #expect(configuration.sections.map(\.features).flatMap(\.self).map(\.id) == [visibleID])
        #expect(configuration.preferences.favoriteFeatureIDs == [disabledID])
        #expect(configuration.preferences.hiddenFeatureIDs == [hiddenID])
    }

    @Test
    func preferencesRoundTripWithStableRawValues() throws {
        let featureID = try featureID("foundation.keep-awake")
        let preferences = try MenuPreferences(
            favoriteFeatureIDs: [featureID],
            hiddenFeatureIDs: [],
            orderedFeatureIDs: [featureID],
            iconChoice: .boltCircle,
            shortcutReferences: [
                featureID: shortcutReference("shortcut.keep-awake")
            ]
        )

        let data = try JSONEncoder().encode(preferences)
        let decoded = try JSONDecoder().decode(MenuPreferences.self, from: data)

        #expect(decoded == preferences)
    }

    @Test
    func preferencesRoundTripThroughVersionedSettingsConfiguration() throws {
        let keepAwakeID = try featureID("foundation.keep-awake")
        let captureTextID = try featureID("foundation.capture-text")
        let preferences = try MenuPreferences(
            favoriteFeatureIDs: [keepAwakeID],
            hiddenFeatureIDs: [captureTextID],
            orderedFeatureIDs: [captureTextID, keepAwakeID],
            iconChoice: .gauge,
            shortcutReferences: [
                captureTextID: shortcutReference("shortcut.capture-text")
            ]
        )
        var settings = SettingsSchema.default

        preferences.write(to: &settings)
        let decoded = MenuPreferences(settings: settings)

        #expect(decoded == preferences)
    }

    @Test
    func malformedStoredPreferenceValuesFallBackSafely() {
        let invalidKey = SettingsKey(rawValue: "menu.favorite-feature-ids")
        var settings = SettingsSchema.default
        settings[.menuFavoriteFeatureIDs] = .stringList(["invalid", "", "No Spaces"])
        settings[.menuIconChoice] = .string("missing-icon")
        settings[.menuShortcutReferences] = .stringList(["invalid", "a=b=c"])

        let preferences = MenuPreferences(settings: settings)

        #expect(invalidKey == .menuFavoriteFeatureIDs)
        #expect(preferences == .default)
    }

    private func featureID(_ rawValue: String) throws -> FeatureID {
        try #require(FeatureID(rawValue: rawValue))
    }

    private func shortcutReference(_ rawValue: String) throws -> MenuShortcutReference {
        try #require(MenuShortcutReference(rawValue: rawValue))
    }

    private func factory(
        id: FeatureID,
        category: FeatureCategory = .foundation,
        supportsGlobalShortcut: Bool = false
    ) -> FeatureFactory {
        FeatureFactory(id: id) {
            FeatureFixtures.descriptor(
                id: id,
                category: category,
                supportsGlobalShortcut: supportsGlobalShortcut
            )
        }
    }
}
