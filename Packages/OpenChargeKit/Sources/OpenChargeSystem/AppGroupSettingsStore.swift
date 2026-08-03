import Foundation
import OpenChargeCore

public protocol SettingsDataBacking: Sendable {
    func data(forKey key: String) async throws -> Data?
    func set(_ data: Data, forKey key: String) async throws
}

public protocol SettingsDataCoding: Sendable {
    func decode(_ data: Data?) throws -> SettingsSchema
    func encode(_ settings: SettingsSchema) throws -> Data
}

extension SettingsCodec: SettingsDataCoding {}

public actor UserDefaultsSettingsDataBacking: SettingsDataBacking {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    public func set(_ data: Data, forKey key: String) {
        userDefaults.set(data, forKey: key)
    }
}

public actor AppGroupSettingsStore: SettingsStore {
    public static let appGroupIdentifier = "group.studio.orbitlabs.opencharge"
    public static let settingsKey = "studio.orbitlabs.opencharge.app-settings"

    private let dataBacking: any SettingsDataBacking
    private let codec: any SettingsDataCoding
    private let key: String

    public init(
        dataBacking: any SettingsDataBacking,
        codec: any SettingsDataCoding = SettingsCodec(),
        key: String = settingsKey
    ) {
        self.dataBacking = dataBacking
        self.codec = codec
        self.key = key
    }

    public init?(
        suiteName: String = appGroupIdentifier,
        codec: any SettingsDataCoding = SettingsCodec(),
        key: String = settingsKey
    ) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }

        dataBacking = UserDefaultsSettingsDataBacking(userDefaults: userDefaults)
        self.codec = codec
        self.key = key
    }

    public func snapshot() async throws -> SettingsSchema {
        let data = try await dataBacking.data(forKey: key)
        return try codec.decode(data)
    }

    @discardableResult
    public func update(
        _ mutation: @Sendable (inout SettingsSchema) throws -> Void
    ) async throws -> SettingsSchema {
        var updated = try await snapshot()
        try mutation(&updated)
        let encoded = try codec.encode(updated)
        try await dataBacking.set(encoded, forKey: key)
        return updated
    }
}
