import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Settings schema")
struct SettingsSchemaTests {
    @Test
    func versionOneDefaultsKeepEveryCapabilityDisabled() throws {
        let featureID = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let settings = SettingsSchema.default

        #expect(settings.schemaVersion == 1)
        #expect(settings.enabledFeatureIDs.isEmpty)
        #expect(settings.isFeatureEnabled(featureID) == false)
        #expect(settings[.launchAtLogin] == .boolean(false))
        #expect(settings[.showsMenuBarIcon] == .boolean(true))
        #expect(settings[.appearance] == .string("system"))
    }

    @Test
    func featureEnablementUsesStableIdentifiers() throws {
        let enabledID = try #require(FeatureID(rawValue: "finder.copy-path"))
        let disabledID = try #require(FeatureID(rawValue: "finder.open-terminal"))
        var settings = SettingsSchema.default

        settings.setFeature(enabledID, enabled: true)

        #expect(settings.isFeatureEnabled(enabledID))
        #expect(settings.isFeatureEnabled(disabledID) == false)

        settings.setFeature(enabledID, enabled: false)
        #expect(settings.enabledFeatureIDs.isEmpty)
    }

    @Test
    func settingsKeysRejectUnstableValues() {
        #expect(SettingsKey(rawValue: "") == nil)
        #expect(SettingsKey(rawValue: "Launch At Login") == nil)
        #expect(SettingsKey(rawValue: "general_launch-at-login") == nil)
        #expect(SettingsKey(rawValue: "general.launch-at-login") == .launchAtLogin)
    }

    @Test
    func schemaRoundTripsSharedConfiguration() throws {
        let customKey = try #require(SettingsKey(rawValue: "foundation.capture-text.languages"))
        var settings = SettingsSchema.default
        settings[customKey] = .stringList(["en-CA", "fr-CA"])

        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(SettingsSchema.self, from: encoded)

        #expect(decoded == settings)
        #expect(decoded[customKey] == .stringList(["en-CA", "fr-CA"]))
    }
}
