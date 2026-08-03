import OpenChargeCore
import ServiceManagement

@MainActor
protocol LaunchAtLoginService: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

@MainActor
private final class SystemLaunchAtLoginService: LaunchAtLoginService {
    private let service: SMAppService

    init(service: SMAppService) {
        self.service = service
    }

    var status: SMAppService.Status {
        service.status
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }
}

@MainActor
public final class LaunchAtLoginController: LaunchAtLoginControlling {
    private let service: any LaunchAtLoginService

    public convenience init() {
        self.init(service: SystemLaunchAtLoginService(service: .mainApp))
    }

    init(service: any LaunchAtLoginService) {
        self.service = service
    }

    public var status: LaunchAtLoginStatus {
        Self.map(service.status)
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            throw enabled
                ? LaunchAtLoginError.registrationFailed
                : LaunchAtLoginError.unregistrationFailed
        }

        let observedStatus = status
        if enabled, observedStatus.isRegistered {
            return observedStatus
        }
        if !enabled, observedStatus == .disabled {
            return observedStatus
        }

        throw enabled
            ? LaunchAtLoginError.registrationFailed
            : LaunchAtLoginError.unregistrationFailed
    }

    static func map(_ status: SMAppService.Status) -> LaunchAtLoginStatus {
        switch status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable(reasonKey: "launchAtLogin.serviceNotFound")
        @unknown default:
            .unavailable(reasonKey: "launchAtLogin.statusUnknown")
        }
    }
}
