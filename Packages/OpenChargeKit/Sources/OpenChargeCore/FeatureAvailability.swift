public enum FeatureRecoveryKind: String, Codable, Sendable {
    case enableFeature
    case openSystemSettings
    case retry
}

public struct FeatureRecovery: Hashable, Codable, Sendable {
    public let kind: FeatureRecoveryKind
    public let titleKey: String

    public init(kind: FeatureRecoveryKind, titleKey: String) {
        self.kind = kind
        self.titleKey = titleKey
    }
}

public enum FeatureAvailability: Hashable, Codable, Sendable {
    case available
    case disabled
    case missingPermission(reasonKey: String, recovery: FeatureRecovery)
    case unsupported(reasonKey: String)

    public var isAvailable: Bool {
        self == .available
    }

    public var recovery: FeatureRecovery? {
        switch self {
        case let .missingPermission(_, recovery):
            recovery
        case .available, .disabled, .unsupported:
            nil
        }
    }
}
