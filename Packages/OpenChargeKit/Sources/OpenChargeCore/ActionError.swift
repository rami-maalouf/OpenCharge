public enum ActionError: Error, Hashable, Codable, Sendable {
    case cancelled
    case conflict(reasonKey: String)
    case invalidInput(reasonKey: String)
    case missingPermission(
        kind: PermissionKind,
        state: PermissionState,
        recovery: FeatureRecovery
    )
    case partialSuccess(succeededCount: Int, failedCount: Int, reasonKey: String)
    case systemFailure(reasonKey: String)
    case unavailable(reasonKey: String, recovery: FeatureRecovery?)

    public var recovery: FeatureRecovery? {
        switch self {
        case let .missingPermission(_, _, recovery):
            recovery
        case let .unavailable(_, recovery):
            recovery
        case .cancelled, .conflict, .invalidInput, .partialSuccess, .systemFailure:
            nil
        }
    }
}
