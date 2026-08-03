import Observation
import OpenChargeCore
import OpenChargeSystem

struct FinderExtensionCapability {
    let currentStatus: @Sendable () async -> FinderExtensionStatus
    let openManagement: @MainActor @Sendable () -> Void

    static func live(arguments: [String]) -> Self {
        if let status = deterministicStatus(arguments: arguments) {
            return Self(
                currentStatus: { status },
                openManagement: {}
            )
        }

        let provider = FinderExtensionStatusProvider()
        return Self(
            currentStatus: { await provider.currentStatus() },
            openManagement: { provider.openManagementInterface() }
        )
    }

    static let preview = Self(
        currentStatus: {
            FinderExtensionStatus(
                installation: .installed,
                activation: .disabled
            )
        },
        openManagement: {}
    )

    private static func deterministicStatus(
        arguments: [String]
    ) -> FinderExtensionStatus? {
        let flag = "--ui-permission-finderSync"
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }

        switch arguments[index + 1] {
        case "granted":
            return FinderExtensionStatus(
                installation: .installed,
                activation: .enabled
            )
        case "denied", "notDetermined", "restricted":
            return FinderExtensionStatus(
                installation: .installed,
                activation: .disabled
            )
        case "notInstalled":
            return FinderExtensionStatus(
                installation: .notInstalled,
                activation: .unavailable(
                    reasonKey: "permission.finderSync.notInstalled"
                )
            )
        case "unavailable":
            return FinderExtensionStatus(
                installation: .unavailable(
                    reasonKey: "permission.test.unavailable"
                ),
                activation: .unavailable(
                    reasonKey: "permission.test.unavailable"
                )
            )
        default:
            return nil
        }
    }
}

@MainActor
@Observable
final class FinderSettingsModel {
    private nonisolated static let copyPathFeatureID: FeatureID = {
        guard let id = FeatureID(rawValue: "finder.copy-path") else {
            preconditionFailure("invalid Copy Path feature identifier")
        }
        return id
    }()

    private let capability: FinderExtensionCapability
    private let settingsStore: any SettingsStore

    private var hasLoaded = false
    private(set) var extensionStatus: FinderExtensionStatus?
    private(set) var isCopyPathEnabled = false
    private(set) var isUpdating = false
    private(set) var settingsError: ActionError?

    init(
        settingsStore: any SettingsStore,
        capability: FinderExtensionCapability
    ) {
        self.settingsStore = settingsStore
        self.capability = capability
    }

    func load() async {
        guard !hasLoaded, beginUpdate() else {
            return
        }
        defer { isUpdating = false }

        extensionStatus = await capability.currentStatus()
        do {
            let settings = try await settingsStore.snapshot()
            isCopyPathEnabled = settings.isFeatureEnabled(
                Self.copyPathFeatureID
            )
            settingsError = nil
            hasLoaded = true
        } catch {
            settingsError = .systemFailure(
                reasonKey: "feature.copyPath.settingsLoadFailed"
            )
        }
    }

    func refreshStatus() async {
        extensionStatus = await capability.currentStatus()
    }

    func setCopyPathEnabled(_ enabled: Bool) async {
        guard beginUpdate() else {
            return
        }
        defer { isUpdating = false }

        let featureID = Self.copyPathFeatureID
        do {
            let settings = try await settingsStore.update { settings in
                settings.setFeature(featureID, enabled: enabled)
            }
            isCopyPathEnabled = settings.isFeatureEnabled(featureID)
            settingsError = nil
            hasLoaded = true
        } catch {
            settingsError = .systemFailure(
                reasonKey: "feature.copyPath.settingsUpdateFailed"
            )
        }
    }

    func openExtensionManagement() {
        capability.openManagement()
    }

    private func beginUpdate() -> Bool {
        guard !isUpdating else {
            return false
        }
        isUpdating = true
        return true
    }
}
