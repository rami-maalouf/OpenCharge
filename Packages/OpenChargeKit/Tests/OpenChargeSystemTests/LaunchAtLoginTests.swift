@testable import OpenChargeCore
@testable import OpenChargeSystem
import ServiceManagement
import Testing

@Suite("Launch at login")
struct LaunchAtLoginTests {
    @MainActor
    @Test
    func mapsEveryServiceManagementStatus() {
        #expect(LaunchAtLoginController.map(.notRegistered) == .disabled)
        #expect(LaunchAtLoginController.map(.enabled) == .enabled)
        #expect(LaunchAtLoginController.map(.requiresApproval) == .requiresApproval)
        #expect(
            LaunchAtLoginController.map(.notFound)
                == .unavailable(reasonKey: "launchAtLogin.serviceNotFound")
        )
    }

    @MainActor
    @Test
    func reportsRegistrationFailureWithoutClaimingEnabled() {
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        service.registrationError = ServiceFailure.expected
        let controller = LaunchAtLoginController(service: service)

        #expect(throws: LaunchAtLoginError.registrationFailed) {
            try controller.setEnabled(true)
        }
        #expect(controller.status == .disabled)
    }

    @MainActor
    @Test
    func returnsObservedStatusAfterSuccessfulChange() throws {
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        let controller = LaunchAtLoginController(service: service)

        #expect(try controller.setEnabled(true) == .enabled)
        #expect(try controller.setEnabled(false) == .disabled)
    }
}

@MainActor
private final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: SMAppService.Status
    var registrationError: (any Error)?
    var unregistrationError: (any Error)?

    init(status: SMAppService.Status) {
        self.status = status
    }

    func register() throws {
        if let registrationError {
            throw registrationError
        }
        status = .enabled
    }

    func unregister() throws {
        if let unregistrationError {
            throw unregistrationError
        }
        status = .notRegistered
    }
}

private enum ServiceFailure: Error {
    case expected
}
