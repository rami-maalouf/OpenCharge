public protocol SettingsStore: Sendable {
    func snapshot() async throws -> SettingsSchema

    @discardableResult
    func update(
        _ mutation: @Sendable (inout SettingsSchema) throws -> Void
    ) async throws -> SettingsSchema
}
