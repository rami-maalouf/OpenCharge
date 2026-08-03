public enum LaunchAtLoginStatus: Equatable, Codable, Sendable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable(reasonKey: String)

    public var isRegistered: Bool {
        switch self {
        case .enabled, .requiresApproval:
            true
        case .disabled, .unavailable:
            false
        }
    }
}

public enum LaunchAtLoginError: Error, Equatable, Sendable {
    case registrationFailed
    case unregistrationFailed
    case unavailable
}

@MainActor
public protocol LaunchAtLoginControlling: Sendable {
    var status: LaunchAtLoginStatus { get }

    @discardableResult
    func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus
}
