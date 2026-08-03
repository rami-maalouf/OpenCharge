import OpenChargeCore

enum AccessibilityID {
    static let menuBar = "menuBar.openCharge"

    enum Menu {
        static let about = "menu.about"
        static let health = "menu.health"
        static let quit = "menu.quit"
        static let settings = "menu.settings"
    }

    enum Settings {
        static let appearance = "settings.general.appearance"
        static let launchAtLogin = "settings.general.launchAtLogin"

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
