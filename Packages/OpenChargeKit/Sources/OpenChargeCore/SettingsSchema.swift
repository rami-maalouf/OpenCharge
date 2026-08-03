public enum SettingsValue: Equatable, Codable, Sendable {
    case boolean(Bool)
    case integer(Int)
    case string(String)
    case stringList([String])
}

public struct SettingsSchema: Equatable, Codable, Sendable {
    public static let currentVersion = 1
    public static let `default` = Self(
        schemaVersion: currentVersion,
        enabledFeatureIDs: [],
        configuration: [
            .appearance: .string("system"),
            .launchAtLogin: .boolean(false),
            .showsMenuBarIcon: .boolean(true)
        ]
    )

    public let schemaVersion: Int
    public private(set) var enabledFeatureIDs: Set<FeatureID>
    public private(set) var configuration: [SettingsKey: SettingsValue]

    public init(
        schemaVersion: Int,
        enabledFeatureIDs: Set<FeatureID>,
        configuration: [SettingsKey: SettingsValue]
    ) {
        self.schemaVersion = schemaVersion
        self.enabledFeatureIDs = enabledFeatureIDs
        self.configuration = configuration
    }

    public subscript(key: SettingsKey) -> SettingsValue? {
        get {
            configuration[key]
        }
        set {
            configuration[key] = newValue
        }
    }

    public func isFeatureEnabled(_ id: FeatureID) -> Bool {
        enabledFeatureIDs.contains(id)
    }

    public mutating func setFeature(_ id: FeatureID, enabled: Bool) {
        if enabled {
            enabledFeatureIDs.insert(id)
        } else {
            enabledFeatureIDs.remove(id)
        }
    }
}
