import Observation
import OpenChargeCore

enum AppLoadState: Equatable {
    case failed
    case idle
    case loaded
    case loading
}

@MainActor
@Observable
final class AppModel {
    let registry: FeatureRegistry
    let hasPersistentSettings: Bool

    private let settingsStore: any SettingsStore

    private(set) var loadState = AppLoadState.idle
    private(set) var settings = SettingsSchema.default

    init(dependencies: AppDependencies) {
        registry = dependencies.registry
        settingsStore = dependencies.settingsStore
        hasPersistentSettings = dependencies.hasPersistentSettings
    }

    func load() async {
        loadState = .loading
        do {
            settings = try await settingsStore.snapshot()
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }
}
