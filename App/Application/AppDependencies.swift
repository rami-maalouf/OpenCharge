import Foundation
import OpenChargeCore
import OpenChargeSystem

@MainActor
struct AppDependencies {
    let registry: FeatureRegistry
    let settingsStore: any SettingsStore
    let hasPersistentSettings: Bool
    let launchAtLoginController: any LaunchAtLoginControlling
    let permissionCapabilities: [PermissionCapability]

    init(
        registry: FeatureRegistry,
        settingsStore: any SettingsStore,
        hasPersistentSettings: Bool,
        launchAtLoginController: any LaunchAtLoginControlling = PreviewLaunchAtLoginController(),
        permissionCapabilities: [PermissionCapability] = PermissionCapability.preview
    ) {
        self.registry = registry
        self.settingsStore = settingsStore
        self.hasPersistentSettings = hasPersistentSettings
        self.launchAtLoginController = launchAtLoginController
        self.permissionCapabilities = permissionCapabilities
    }

    static var live: Self {
        let registry = FeatureRegistry(factories: [])
        if let settingsStore = AppGroupSettingsStore() {
            return Self(
                registry: registry,
                settingsStore: settingsStore,
                hasPersistentSettings: true,
                launchAtLoginController: LaunchAtLoginController(),
                permissionCapabilities: PermissionCapability.live(
                    arguments: ProcessInfo.processInfo.arguments
                )
            )
        }

        return Self(
            registry: registry,
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false,
            permissionCapabilities: PermissionCapability.live(
                arguments: ProcessInfo.processInfo.arguments
            )
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

@MainActor
final class PreviewLaunchAtLoginController: LaunchAtLoginControlling {
    private(set) var status: LaunchAtLoginStatus

    init(status: LaunchAtLoginStatus = .disabled) {
        self.status = status
    }

    func setEnabled(_ enabled: Bool) -> LaunchAtLoginStatus {
        status = enabled ? .enabled : .disabled
        return status
    }
}
