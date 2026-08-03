import OpenChargeCore

public actor InMemorySettingsStore: SettingsStore {
    private var settings: SettingsSchema

    public init(initial: SettingsSchema = .default) {
        settings = initial
    }

    public func snapshot() -> SettingsSchema {
        settings
    }

    @discardableResult
    public func update(
        _ mutation: @Sendable (inout SettingsSchema) throws -> Void
    ) throws -> SettingsSchema {
        var updated = settings
        try mutation(&updated)
        settings = updated
        return updated
    }
}
