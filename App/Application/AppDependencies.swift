import Foundation
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem

@MainActor
struct AppDependencies {
    let registry: FeatureRegistry
    let baselineFeatureIDs: Set<FeatureID>
    let settingsStore: any SettingsStore
    let hasPersistentSettings: Bool
    let finderExtensionCapability: FinderExtensionCapability
    let keepAwakeAction: KeepAwakeAction
    let launchAtLoginController: any LaunchAtLoginControlling
    let permissionCapabilities: [PermissionCapability]

    init(
        registry: FeatureRegistry,
        baselineFeatureIDs: Set<FeatureID> = [],
        settingsStore: any SettingsStore,
        hasPersistentSettings: Bool,
        finderExtensionCapability: FinderExtensionCapability = .preview,
        keepAwakeController: any KeepAwakeControlling = PreviewKeepAwakeController(),
        launchAtLoginController: any LaunchAtLoginControlling = PreviewLaunchAtLoginController(),
        permissionCapabilities: [PermissionCapability] = PermissionCapability.preview
    ) {
        self.registry = registry
        self.baselineFeatureIDs = baselineFeatureIDs
        self.settingsStore = settingsStore
        self.hasPersistentSettings = hasPersistentSettings
        self.finderExtensionCapability = finderExtensionCapability
        keepAwakeAction = KeepAwakeAction(controller: keepAwakeController)
        self.launchAtLoginController = launchAtLoginController
        self.permissionCapabilities = permissionCapabilities
    }

    static var live: Self {
        let arguments = ProcessInfo.processInfo.arguments
        let catalog = FeatureCatalog(arguments: arguments)
        let keepAwakeController: any KeepAwakeControlling = if arguments.contains(
            "--ui-preview-keep-awake"
        ) {
            PreviewKeepAwakeController()
        } else {
            PowerAssertionController()
        }
        if arguments.contains("--ui-in-memory-settings") {
            return Self(
                registry: catalog.registry,
                baselineFeatureIDs: catalog.baselineFeatureIDs,
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
                registry: catalog.registry,
                baselineFeatureIDs: catalog.baselineFeatureIDs,
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
            registry: catalog.registry,
            baselineFeatureIDs: catalog.baselineFeatureIDs,
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
        let catalog = FeatureCatalog(arguments: [])
        return Self(
            registry: catalog.registry,
            baselineFeatureIDs: catalog.baselineFeatureIDs,
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false
        )
    }
}

private struct FeatureCatalog {
    let registry: FeatureRegistry
    let baselineFeatureIDs: Set<FeatureID>

    init(arguments: [String]) {
        let keepAwake = Self.feature(
            rawID: "foundation.keep-awake",
            category: .foundation,
            titleKey: "Keep Awake",
            descriptionKey: "Controls whether OpenCharge prevents system or display sleep.",
            supportsGlobalShortcut: true,
            supportsAppIntent: true
        )
        var features = [keepAwake].compactMap(\.self)

        if arguments.contains("--ui-menu-fixtures") {
            features += [
                Self.feature(
                    rawID: "foundation.capture-text",
                    category: .foundation,
                    titleKey: "Capture Text",
                    descriptionKey: "Recognize text in a selected screen region.",
                    supportsGlobalShortcut: true,
                    supportsAppIntent: true
                ),
                Self.feature(
                    rawID: "foundation.clear-clipboard",
                    category: .foundation,
                    titleKey: "Clear Clipboard",
                    descriptionKey: "Clear the current clipboard contents without retaining history.",
                    supportsGlobalShortcut: true,
                    supportsAppIntent: true
                )
            ].compactMap(\.self)
        }

        registry = FeatureRegistry(factories: features.map { descriptor in
            FeatureFactory(id: descriptor.id) { descriptor }
        })
        baselineFeatureIDs = Set(features.map(\.id))
    }

    private static func feature(
        rawID: String,
        category: FeatureCategory,
        titleKey: String,
        descriptionKey: String,
        supportsGlobalShortcut: Bool,
        supportsAppIntent: Bool
    ) -> FeatureDescriptor? {
        guard let id = FeatureID(rawValue: rawID) else {
            return nil
        }
        return FeatureDescriptor(
            id: id,
            category: category,
            titleKey: titleKey,
            descriptionKey: descriptionKey,
            supportsGlobalShortcut: supportsGlobalShortcut,
            supportsAppIntent: supportsAppIntent
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
