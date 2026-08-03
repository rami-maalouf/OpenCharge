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
    let launchAtLogin: LaunchAtLoginModel

    private let settingsStore: any SettingsStore

    private(set) var loadState = AppLoadState.idle
    private(set) var settings = SettingsSchema.default

    init(dependencies: AppDependencies) {
        registry = dependencies.registry
        settingsStore = dependencies.settingsStore
        hasPersistentSettings = dependencies.hasPersistentSettings
        launchAtLogin = LaunchAtLoginModel(controller: dependencies.launchAtLoginController)
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

    func setSetting(_ value: SettingsValue?, for key: SettingsKey) async {
        do {
            settings = try await settingsStore.update { settings in
                settings[key] = value
            }
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }
}
