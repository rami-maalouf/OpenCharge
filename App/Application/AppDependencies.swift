import OpenChargeCore
import OpenChargeSystem

@MainActor
struct AppDependencies {
    let registry: FeatureRegistry
    let settingsStore: any SettingsStore
    let hasPersistentSettings: Bool

    static var live: Self {
        let registry = FeatureRegistry(factories: [])
        if let settingsStore = AppGroupSettingsStore() {
            return Self(
                registry: registry,
                settingsStore: settingsStore,
                hasPersistentSettings: true
            )
        }

        return Self(
            registry: registry,
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false
        )
    }

    static var preview: Self {
        Self(
            registry: FeatureRegistry(factories: []),
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false
        )
    }
}
