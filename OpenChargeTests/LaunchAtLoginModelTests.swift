@testable import OpenCharge
import OpenChargeCore
import XCTest

final class LaunchAtLoginModelTests: XCTestCase {
    @MainActor
    func testSuccessfulRegistrationUsesObservedControllerState() {
        let controller = FakeLaunchAtLoginController(status: .disabled)
        let model = LaunchAtLoginModel(controller: controller)

        model.setEnabled(true)

        XCTAssertEqual(model.status, .enabled)
        XCTAssertTrue(model.isEnabled)
        XCTAssertNil(model.error)
    }

    @MainActor
    func testRegistrationFailureNeverClaimsSuccess() {
        let controller = FakeLaunchAtLoginController(status: .disabled)
        controller.nextError = .registrationFailed
        let model = LaunchAtLoginModel(controller: controller)

        model.setEnabled(true)

        XCTAssertEqual(model.status, .disabled)
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(model.error, .registrationFailed)
    }

    @MainActor
    func testRequiresApprovalRemainsVisiblyRegistered() {
        let controller = FakeLaunchAtLoginController(status: .requiresApproval)
        let model = LaunchAtLoginModel(controller: controller)

        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(model.requiresApproval)
    }
}

@MainActor
private final class FakeLaunchAtLoginController: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus
    var nextError: LaunchAtLoginError?

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
        if let nextError {
            throw nextError
        }
        status = enabled ? .enabled : .disabled
        return status
    }
}
