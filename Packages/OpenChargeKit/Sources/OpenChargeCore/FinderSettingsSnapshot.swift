public enum FinderSettingsSnapshotError: Error, Equatable, Sendable {
    case incompatibleVersion(Int)
    case nonFinderFeature
    case nonFinderSetting
}

public struct FinderSettingsSnapshot: Equatable, Codable, Sendable {
    public static let currentVersion = 1

    public let schemaVersion: Int
    public let enabledFeatureIDs: Set<FeatureID>
    public let configuration: [SettingsKey: SettingsValue]

    public init(settings: SettingsSchema) throws {
        guard settings.schemaVersion == Self.currentVersion else {
            throw FinderSettingsSnapshotError.incompatibleVersion(settings.schemaVersion)
        }

        schemaVersion = Self.currentVersion
        enabledFeatureIDs = settings.enabledFeatureIDs.filter(Self.isFinderFeature)
        configuration = settings.configuration.filter { key, _ in
            Self.isFinderSetting(key)
        }
    }

    public func isFeatureEnabled(_ id: FeatureID) -> Bool {
        enabledFeatureIDs.contains(id)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == Self.currentVersion else {
            throw FinderSettingsSnapshotError.incompatibleVersion(schemaVersion)
        }

        let enabledFeatureIDs = try container.decode([FeatureID].self, forKey: .enabledFeatureIDs)
        guard enabledFeatureIDs.allSatisfy(Self.isFinderFeature) else {
            throw FinderSettingsSnapshotError.nonFinderFeature
        }

        let rawConfiguration = try container.decode(
            [String: SettingsValue].self,
            forKey: .configuration
        )
        var configuration: [SettingsKey: SettingsValue] = [:]
        for (rawKey, value) in rawConfiguration {
            guard let key = SettingsKey(rawValue: rawKey), Self.isFinderSetting(key) else {
                throw FinderSettingsSnapshotError.nonFinderSetting
            }
            configuration[key] = value
        }

        self.schemaVersion = schemaVersion
        self.enabledFeatureIDs = Set(enabledFeatureIDs)
        self.configuration = configuration
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(enabledFeatureIDs.sorted(), forKey: .enabledFeatureIDs)
        try container.encode(
            Dictionary(uniqueKeysWithValues: configuration.map { ($0.key.rawValue, $0.value) }),
            forKey: .configuration
        )
    }

    private enum CodingKeys: String, CodingKey {
        case configuration
        case enabledFeatureIDs
        case schemaVersion
    }

    private static func isFinderFeature(_ id: FeatureID) -> Bool {
        id.rawValue.hasPrefix("finder.")
    }

    private static func isFinderSetting(_ key: SettingsKey) -> Bool {
        key.rawValue.hasPrefix("finder.")
    }
}
