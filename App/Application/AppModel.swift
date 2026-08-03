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
    let finder: FinderSettingsModel
    let keepAwake: KeepAwakeModel
    let launchAtLogin: LaunchAtLoginModel
    let permissions: PermissionsModel

    private let settingsStore: any SettingsStore

    private(set) var loadState = AppLoadState.idle
    private(set) var settings = SettingsSchema.default

    init(dependencies: AppDependencies) {
        registry = dependencies.registry
        settingsStore = dependencies.settingsStore
        hasPersistentSettings = dependencies.hasPersistentSettings
        finder = FinderSettingsModel(
            settingsStore: dependencies.settingsStore,
            capability: dependencies.finderExtensionCapability
        )
        keepAwake = KeepAwakeModel(
            action: dependencies.keepAwakeAction,
            settingsStore: dependencies.settingsStore
        )
        launchAtLogin = LaunchAtLoginModel(controller: dependencies.launchAtLoginController)
        permissions = PermissionsModel(capabilities: dependencies.permissionCapabilities)
    }

    func load() async {
        loadState = .loading
        do {
            settings = try await settingsStore.snapshot()
            loadState = .loaded
        } catch {
            loadState = .failed
        }
        await keepAwake.load()
        await finder.load()
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

    func refreshPermissions() async {
        await permissions.refresh()
    }

    func didBecomeActive() async {
        await refreshPermissions()
        await finder.refreshStatus()
    }
}
