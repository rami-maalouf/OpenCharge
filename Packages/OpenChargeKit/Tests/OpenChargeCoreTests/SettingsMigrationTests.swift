import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Settings migration")
struct SettingsMigrationTests {
    @Test
    func missingDataDecodesAsSafeDefaults() throws {
        let settings = try SettingsCodec().decode(nil)

        #expect(settings == .default)
    }

    @Test
    func versionOneRoundTrips() throws {
        let featureID = try #require(FeatureID(rawValue: "finder.copy-path"))
        var settings = SettingsSchema.default
        settings.setFeature(featureID, enabled: true)
        let codec = SettingsCodec()

        let encoded = try codec.encode(settings)
        let decoded = try codec.decode(encoded)

        #expect(decoded == settings)
    }

    @Test
    func corruptDataFailsWithoutMutation() {
        let data = Data("not-json".utf8)
        let original = data

        #expect(throws: SettingsCodecError.corruptData) {
            try SettingsCodec().decode(data)
        }
        #expect(data == original)
    }

    @Test
    func futureVersionFailsBeforeDecodingPayload() {
        let data = Data(#"{"schemaVersion":2}"#.utf8)

        #expect(throws: SettingsCodecError.futureVersion(2)) {
            try SettingsCodec().decode(data)
        }
    }

    @Test
    func migrationIsIdempotentForCurrentSchema() throws {
        let migrator = SettingsMigrator()
        let once = try migrator.migrate(.default)
        let twice = try migrator.migrate(once)

        #expect(once == .default)
        #expect(twice == once)
    }

    @Test
    func invalidPastVersionIsRejected() {
        let invalid = SettingsSchema(
            schemaVersion: 0,
            enabledFeatureIDs: [],
            configuration: [:]
        )

        #expect(throws: SettingsMigrationError.unsupportedVersion(0)) {
            try SettingsMigrator().migrate(invalid)
        }
    }
}
