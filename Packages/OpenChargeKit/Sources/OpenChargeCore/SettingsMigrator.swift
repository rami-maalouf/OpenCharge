public enum SettingsMigrationError: Error, Equatable, Sendable {
    case futureVersion(Int)
    case unsupportedVersion(Int)
}

public struct SettingsMigrator: Sendable {
    public init() {}

    public func migrate(_ settings: SettingsSchema) throws -> SettingsSchema {
        switch settings.schemaVersion {
        case SettingsSchema.currentVersion:
            settings
        case ..<SettingsSchema.currentVersion:
            throw SettingsMigrationError.unsupportedVersion(settings.schemaVersion)
        default:
            throw SettingsMigrationError.futureVersion(settings.schemaVersion)
        }
    }
}
