public struct SettingsKey: RawRepresentable, Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init?(rawValue: String) {
        guard FeatureID(rawValue: rawValue) != nil else {
            return nil
        }
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static let appearance = Self(uncheckedRawValue: "general.appearance")
    public static let launchAtLogin = Self(uncheckedRawValue: "general.launch-at-login")
    public static let showsMenuBarIcon = Self(uncheckedRawValue: "general.shows-menu-bar-icon")

    private init(uncheckedRawValue: String) {
        rawValue = uncheckedRawValue
    }
}
