public enum PermissionState: Hashable, Codable, Sendable {
    case denied
    case granted
    case notDetermined
    case restricted
    case unavailable(reasonKey: String)

    public var isGranted: Bool {
        self == .granted
    }
}
