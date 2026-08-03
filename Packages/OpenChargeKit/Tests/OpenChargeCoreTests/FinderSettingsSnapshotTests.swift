import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Finder settings snapshot")
struct FinderSettingsSnapshotTests {
    @Test
    func filtersAppSettingsToFinderRelevantValues() throws {
        let finderID = try #require(FeatureID(rawValue: "finder.copy-path"))
        let foundationID = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let finderKey = try #require(SettingsKey(rawValue: "finder.copy-path.style"))
        var settings = SettingsSchema.default
        settings.setFeature(finderID, enabled: true)
        settings.setFeature(foundationID, enabled: true)
        settings[finderKey] = .string("posix")

        let snapshot = try FinderSettingsSnapshot(settings: settings)

        #expect(snapshot.enabledFeatureIDs == [finderID])
        #expect(snapshot.configuration == [finderKey: .string("posix")])
        #expect(snapshot.isFeatureEnabled(finderID))
        #expect(snapshot.isFeatureEnabled(foundationID) == false)
    }

    @Test
    func versionOneFixtureRoundTrips() throws {
        let fixture = Data(
            #"{"schemaVersion":1,"enabledFeatureIDs":["finder.copy-path"],"configuration":{"finder.copy-path.style":{"string":{"_0":"posix"}}}}"#.utf8
        )

        let decoded = try JSONDecoder().decode(FinderSettingsSnapshot.self, from: fixture)
        let encoded = try JSONEncoder().encode(decoded)
        let roundTripped = try JSONDecoder().decode(FinderSettingsSnapshot.self, from: encoded)

        #expect(roundTripped == decoded)
    }

    @Test
    func rejectsFutureSnapshotVersion() {
        let fixture = Data(
            #"{"schemaVersion":2,"enabledFeatureIDs":[],"configuration":{}}"#.utf8
        )

        #expect(throws: FinderSettingsSnapshotError.incompatibleVersion(2)) {
            try JSONDecoder().decode(FinderSettingsSnapshot.self, from: fixture)
        }
    }

    @Test
    func rejectsNonFinderPayloadValues() {
        let fixture = Data(
            #"{"schemaVersion":1,"enabledFeatureIDs":["foundation.keep-awake"],"configuration":{}}"#.utf8
        )

        #expect(throws: FinderSettingsSnapshotError.nonFinderFeature) {
            try JSONDecoder().decode(FinderSettingsSnapshot.self, from: fixture)
        }
    }
}
