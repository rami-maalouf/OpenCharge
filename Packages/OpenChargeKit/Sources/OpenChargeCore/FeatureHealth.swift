public enum FeatureHealth: Hashable, Codable, Sendable {
    case degraded(messageKey: String, recovery: FeatureRecovery?)
    case failed(messageKey: String, recovery: FeatureRecovery?)
    case healthy

    public var isHealthy: Bool {
        self == .healthy
    }

    public var recovery: FeatureRecovery? {
        switch self {
        case let .degraded(_, recovery), let .failed(_, recovery):
            recovery
        case .healthy:
            nil
        }
    }
}
