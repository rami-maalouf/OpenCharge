import OpenChargeCore

enum AccessibilityID {
    static let menuBar = "menuBar.openCharge"

    enum Menu {
        static let about = "menu.about"
        static let health = "menu.health"
        static let keepAwake = "menu.keepAwake"
        static let quit = "menu.quit"
        static let settings = "menu.settings"
    }

    enum Settings {
        static let appearance = "settings.general.appearance"
        static let launchAtLogin = "settings.general.launchAtLogin"

        static let keepAwakeMode = "settings.foundation.keepAwake.mode"
        static let keepAwakeRetry = "settings.foundation.keepAwake.retry"
        static let keepAwakeStatus = "settings.foundation.keepAwake.status"

        static func keepAwakeMode(
            _ configuration: KeepAwakeConfiguration
        ) -> String {
            "settings.foundation.keepAwake.mode.\(configuration.rawValue)"
        }

        static let aboutLicense = "settings.about.license"
        static let aboutPrivacy = "settings.about.privacy"
        static let aboutRepository = "settings.about.repository"
        static let aboutWebsite = "settings.about.website"

        static func section(_ section: SettingsSection) -> String {
            "settings.section.\(section.rawValue)"
        }

        static func sidebar(_ section: SettingsSection) -> String {
            "settings.sidebar.\(section.rawValue)"
        }
    }

    enum Permissions {
        static func explanation(_ kind: PermissionKind) -> String {
            "permissions.explanation.\(kind.rawValue)"
        }

        static func recovery(_ kind: PermissionKind) -> String {
            "permissions.action.\(kind.rawValue).recovery"
        }

        static func request(_ kind: PermissionKind) -> String {
            "permissions.action.\(kind.rawValue).request"
        }

        static func row(_ kind: PermissionKind) -> String {
            "permissions.row.\(kind.rawValue)"
        }

        static func status(_ kind: PermissionKind, state: PermissionState) -> String {
            "permissions.status.\(kind.rawValue).\(state.accessibilityComponent)"
        }
    }

    static func featureRecovery(_ id: FeatureID) -> String {
        "feature.recovery.\(id.rawValue)"
    }

    static func featureRow(_ id: FeatureID) -> String {
        "feature.row.\(id.rawValue)"
    }

    static func featureToggle(_ id: FeatureID) -> String {
        "feature.toggle.\(id.rawValue)"
    }
}

private extension PermissionState {
    var accessibilityComponent: String {
        switch self {
        case .denied:
            "denied"
        case .granted:
            "granted"
        case .notDetermined:
            "notDetermined"
        case .restricted:
            "restricted"
        case .unavailable:
            "unavailable"
        }
    }
}
