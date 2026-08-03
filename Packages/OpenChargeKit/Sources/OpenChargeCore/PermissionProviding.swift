public protocol PermissionProviding: Sendable {
    var kind: PermissionKind { get }

    func currentState() async throws -> PermissionState
}
