@testable import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("Settings store")
struct SettingsStoreTests {
    @Test
    func returnsInitialSnapshotAndCommittedUpdate() async throws {
        let id = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let store: any SettingsStore = InMemorySettingsStore(initial: .default)

        #expect(try await store.snapshot() == .default)

        let updated = try await store.update { settings in
            settings.setFeature(id, enabled: true)
        }

        #expect(updated.isFeatureEnabled(id))
        #expect(try await store.snapshot() == updated)
    }

    @Test
    func failedMutationDoesNotChangeStoredSnapshot() async throws {
        let store: any SettingsStore = InMemorySettingsStore(initial: .default)

        await #expect(throws: MutationFailure.expected) {
            try await store.update { settings in
                settings[.launchAtLogin] = .boolean(true)
                throw MutationFailure.expected
            }
        }

        #expect(try await store.snapshot() == .default)
    }

    @Test
    func concurrentUpdatesAreAtomic() async throws {
        let counterKey = try #require(SettingsKey(rawValue: "test.concurrent-update-count"))
        let store: any SettingsStore = InMemorySettingsStore(initial: .default)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 100 {
                group.addTask {
                    _ = try await store.update { settings in
                        let current: Int = if case let .integer(value) = settings[counterKey] {
                            value
                        } else {
                            0
                        }
                        settings[counterKey] = .integer(current + 1)
                    }
                }
            }
            try await group.waitForAll()
        }

        let snapshot = try await store.snapshot()
        #expect(snapshot[counterKey] == .integer(100))
    }
}

private enum MutationFailure: Error {
    case expected
}
