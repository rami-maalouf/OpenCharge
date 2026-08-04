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
    let menu: MenuSettingsModel
    let permissions: PermissionsModel

    private let baselineFeatureIDs: Set<FeatureID>
    private let settingsStore: any SettingsStore

    private(set) var loadState = AppLoadState.idle
    private(set) var settings = SettingsSchema.default

    init(dependencies: AppDependencies) {
        registry = dependencies.registry
        baselineFeatureIDs = dependencies.baselineFeatureIDs
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
        menu = MenuSettingsModel(
            registry: dependencies.registry,
            settingsStore: dependencies.settingsStore
        )
        permissions = PermissionsModel(capabilities: dependencies.permissionCapabilities)
        menu.configure { [weak self] settings in
            self?.settings = settings
            self?.loadState = .loaded
        }
    }

    func load() async {
        loadState = .loading
        do {
            let snapshot = try await settingsStore.snapshot()
            let missingBaselineFeatureIDs = baselineFeatureIDs.subtracting(
                snapshot.enabledFeatureIDs
            )
            if missingBaselineFeatureIDs.isEmpty {
                settings = snapshot
            } else {
                settings = try await settingsStore.update { settings in
                    for id in missingBaselineFeatureIDs {
                        settings.setFeature(id, enabled: true)
                    }
                }
            }
            menu.load(from: settings)
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
