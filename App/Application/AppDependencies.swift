import Foundation
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem

@MainActor
struct AppDependencies {
    let registry: FeatureRegistry
    let settingsStore: any SettingsStore
    let hasPersistentSettings: Bool
    let finderExtensionCapability: FinderExtensionCapability
    let keepAwakeAction: KeepAwakeAction
    let launchAtLoginController: any LaunchAtLoginControlling
    let permissionCapabilities: [PermissionCapability]

    init(
        registry: FeatureRegistry,
        settingsStore: any SettingsStore,
        hasPersistentSettings: Bool,
        finderExtensionCapability: FinderExtensionCapability = .preview,
        keepAwakeController: any KeepAwakeControlling = PreviewKeepAwakeController(),
        launchAtLoginController: any LaunchAtLoginControlling = PreviewLaunchAtLoginController(),
        permissionCapabilities: [PermissionCapability] = PermissionCapability.preview
    ) {
        self.registry = registry
        self.settingsStore = settingsStore
        self.hasPersistentSettings = hasPersistentSettings
        self.finderExtensionCapability = finderExtensionCapability
        keepAwakeAction = KeepAwakeAction(controller: keepAwakeController)
        self.launchAtLoginController = launchAtLoginController
        self.permissionCapabilities = permissionCapabilities
    }

    static var live: Self {
        let registry = FeatureRegistry(factories: [])
        let arguments = ProcessInfo.processInfo.arguments
        let keepAwakeController: any KeepAwakeControlling = if arguments.contains(
            "--ui-preview-keep-awake"
        ) {
            PreviewKeepAwakeController()
        } else {
            PowerAssertionController()
        }
        if arguments.contains("--ui-in-memory-settings") {
            return Self(
                registry: registry,
                settingsStore: InMemorySettingsStore(),
                hasPersistentSettings: false,
                finderExtensionCapability: .live(arguments: arguments),
                keepAwakeController: keepAwakeController,
                launchAtLoginController: LaunchAtLoginController(),
                permissionCapabilities: PermissionCapability.live(arguments: arguments)
            )
        }

        if let settingsStore = AppGroupSettingsStore() {
            return Self(
                registry: registry,
                settingsStore: settingsStore,
                hasPersistentSettings: true,
                finderExtensionCapability: .live(arguments: arguments),
                keepAwakeController: keepAwakeController,
                launchAtLoginController: LaunchAtLoginController(),
                permissionCapabilities: PermissionCapability.live(
                    arguments: arguments
                )
            )
        }

        return Self(
            registry: registry,
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false,
            finderExtensionCapability: .live(arguments: arguments),
            keepAwakeController: keepAwakeController,
            permissionCapabilities: PermissionCapability.live(
                arguments: arguments
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

private actor PreviewKeepAwakeController: KeepAwakeControlling {
    private var configuration = KeepAwakeConfiguration.disabled

    func currentConfiguration() -> KeepAwakeConfiguration {
        configuration
    }

    func apply(
        _ configuration: KeepAwakeConfiguration
    ) -> KeepAwakeConfiguration {
        self.configuration = configuration
        return configuration
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
