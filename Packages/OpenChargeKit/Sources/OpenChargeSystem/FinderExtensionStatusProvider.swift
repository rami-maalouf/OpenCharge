@preconcurrency import FinderSync
import Foundation
import OpenChargeCore

public enum FinderExtensionInstallationStatus: Hashable, Sendable {
    case installed
    case notInstalled
    case unavailable(reasonKey: String)
}

public enum FinderExtensionActivationStatus: Hashable, Sendable {
    case enabled
    case disabled
    case unavailable(reasonKey: String)
}

public enum FinderExtensionMenuVisibility: Hashable, Sendable {
    case unknown
}

public struct FinderExtensionStatus: Hashable, Sendable {
    public let installation: FinderExtensionInstallationStatus
    public let activation: FinderExtensionActivationStatus
    public let menuVisibility: FinderExtensionMenuVisibility

    public init(
        installation: FinderExtensionInstallationStatus,
        activation: FinderExtensionActivationStatus,
        menuVisibility: FinderExtensionMenuVisibility = .unknown
    ) {
        self.installation = installation
        self.activation = activation
        self.menuVisibility = menuVisibility
    }
}

public struct FinderExtensionStatusProvider: PermissionProviding {
    public static let extensionBundleIdentifier = "studio.orbitlabs.opencharge.finder"

    public let kind = PermissionKind.finderSync

    private let isInstalled: @Sendable () throws -> Bool
    private let isEnabled: @Sendable () throws -> Bool
    private let showManagement: @MainActor @Sendable () -> Void

    public init() {
        isInstalled = {
            guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
                return false
            }

            let extensionURL = pluginsURL.appendingPathComponent("OpenChargeFinder.appex")
            return Bundle(url: extensionURL)?.bundleIdentifier == Self.extensionBundleIdentifier
        }
        isEnabled = {
            FIFinderSyncController.isExtensionEnabled
        }
        showManagement = { @MainActor in
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }

    init(
        isInstalled: @escaping @Sendable () throws -> Bool,
        isEnabled: @escaping @Sendable () throws -> Bool,
        showManagement: @escaping @MainActor @Sendable () -> Void
    ) {
        self.isInstalled = isInstalled
        self.isEnabled = isEnabled
        self.showManagement = showManagement
    }

    public func currentStatus() async -> FinderExtensionStatus {
        let installed: Bool
        do {
            installed = try isInstalled()
        } catch {
            let reasonKey = "permission.finderSync.installationCheckFailed"
            return FinderExtensionStatus(
                installation: .unavailable(reasonKey: reasonKey),
                activation: .unavailable(reasonKey: reasonKey)
            )
        }

        guard installed else {
            return FinderExtensionStatus(
                installation: .notInstalled,
                activation: .unavailable(reasonKey: "permission.finderSync.notInstalled")
            )
        }

        do {
            return try FinderExtensionStatus(
                installation: .installed,
                activation: isEnabled() ? .enabled : .disabled
            )
        } catch {
            return FinderExtensionStatus(
                installation: .installed,
                activation: .unavailable(
                    reasonKey: "permission.finderSync.enablementCheckFailed"
                )
            )
        }
    }

    public func currentState() async -> PermissionState {
        switch await currentStatus().activation {
        case .enabled:
            .granted
        case .disabled:
            .denied
        case let .unavailable(reasonKey):
            .unavailable(reasonKey: reasonKey)
        }
    }

    @MainActor
    public func openManagementInterface() {
        showManagement()
    }
}
