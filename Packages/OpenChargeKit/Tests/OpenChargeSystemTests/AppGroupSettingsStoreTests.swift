import Foundation
@testable import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("App group settings store")
struct AppGroupSettingsStoreTests {
    @Test
    func usesApprovedAppGroupIdentifier() {
        #expect(AppGroupSettingsStore.appGroupIdentifier == "group.studio.orbitlabs.opencharge")
    }

    @Test
    func missingDataReturnsSafeDefaults() async throws {
        let backing = InMemorySettingsDataBacking()
        let store: any SettingsStore = AppGroupSettingsStore(dataBacking: backing)

        #expect(try await store.snapshot() == .default)
    }

    @Test
    func updateCommitsOneCompleteEncodedSnapshot() async throws {
        let id = try #require(FeatureID(rawValue: "finder.copy-path"))
        let backing = InMemorySettingsDataBacking()
        let store: any SettingsStore = AppGroupSettingsStore(dataBacking: backing)

        let updated = try await store.update { settings in
            settings.setFeature(id, enabled: true)
            settings[.launchAtLogin] = .boolean(true)
        }

        let persistedData = try #require(await backing.data(forKey: AppGroupSettingsStore.settingsKey))
        let persisted = try SettingsCodec().decode(persistedData)
        #expect(await backing.writeCount == 1)
        #expect(persisted == updated)
        #expect(persisted.isFeatureEnabled(id))
        #expect(persisted[.launchAtLogin] == .boolean(true))
    }

    @Test
    func encodingFailurePreservesLastValidData() async throws {
        let codec = SettingsCodec()
        let originalData = try codec.encode(.default)
        let backing = InMemorySettingsDataBacking(initialData: originalData)
        let store: any SettingsStore = AppGroupSettingsStore(
            dataBacking: backing,
            codec: FailingEncodeCodec(base: codec)
        )

        await #expect(throws: TestCodecFailure.expected) {
            try await store.update { settings in
                settings[.launchAtLogin] = .boolean(true)
            }
        }

        #expect(await backing.writeCount == 0)
        #expect(await backing.data(forKey: AppGroupSettingsStore.settingsKey) == originalData)
        #expect(try codec.decode(originalData) == .default)
    }
}

private actor InMemorySettingsDataBacking: SettingsDataBacking {
    private var storedData: Data?
    private(set) var writeCount = 0

    init(initialData: Data? = nil) {
        storedData = initialData
    }

    func data(forKey _: String) -> Data? {
        storedData
    }

    func set(_ data: Data, forKey _: String) {
        storedData = data
        writeCount += 1
    }
}

private struct FailingEncodeCodec: SettingsDataCoding {
    let base: SettingsCodec

    func decode(_ data: Data?) throws -> SettingsSchema {
        try base.decode(data)
    }

    func encode(_: SettingsSchema) throws -> Data {
        throw TestCodecFailure.expected
    }
}

private enum TestCodecFailure: Error {
    case expected
}
