import Foundation

public enum SettingsCodecError: Error, Equatable, Sendable {
    case corruptData
    case futureVersion(Int)
    case unsupportedVersion(Int)
}

public struct SettingsCodec: Sendable {
    private struct VersionEnvelope: Decodable {
        let schemaVersion: Int
    }

    private let migrator: SettingsMigrator

    public init(migrator: SettingsMigrator = SettingsMigrator()) {
        self.migrator = migrator
    }

    public func decode(_ data: Data?) throws -> SettingsSchema {
        guard let data else {
            return .default
        }

        let decoder = JSONDecoder()
        let version: Int
        do {
            version = try decoder.decode(VersionEnvelope.self, from: data).schemaVersion
        } catch {
            throw SettingsCodecError.corruptData
        }

        guard version <= SettingsSchema.currentVersion else {
            throw SettingsCodecError.futureVersion(version)
        }

        let settings: SettingsSchema
        do {
            settings = try decoder.decode(SettingsSchema.self, from: data)
        } catch {
            throw SettingsCodecError.corruptData
        }

        return try migrate(settings)
    }

    public func encode(_ settings: SettingsSchema) throws -> Data {
        let migrated = try migrate(settings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(migrated)
    }

    private func migrate(_ settings: SettingsSchema) throws -> SettingsSchema {
        do {
            return try migrator.migrate(settings)
        } catch let error as SettingsMigrationError {
            switch error {
            case let .futureVersion(version):
                throw SettingsCodecError.futureVersion(version)
            case let .unsupportedVersion(version):
                throw SettingsCodecError.unsupportedVersion(version)
            }
        }
    }
}
