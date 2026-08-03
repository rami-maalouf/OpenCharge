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

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid settings key."
            )
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static let appearance = Self(uncheckedRawValue: "general.appearance")
    public static let keepAwakeConfiguration = Self(
        uncheckedRawValue: "foundation.keep-awake.configuration"
    )
    public static let launchAtLogin = Self(uncheckedRawValue: "general.launch-at-login")
    public static let showsMenuBarIcon = Self(uncheckedRawValue: "general.shows-menu-bar-icon")

    private init(uncheckedRawValue: String) {
        rawValue = uncheckedRawValue
    }
}
