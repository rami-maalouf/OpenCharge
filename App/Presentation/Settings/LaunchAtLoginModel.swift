import Observation
import OpenChargeCore

@MainActor
@Observable
final class LaunchAtLoginModel {
    private let controller: any LaunchAtLoginControlling

    private(set) var error: LaunchAtLoginError?
    private(set) var isUpdating = false
    private(set) var status: LaunchAtLoginStatus

    init(controller: any LaunchAtLoginControlling) {
        self.controller = controller
        status = controller.status
    }

    var isEnabled: Bool {
        status.isRegistered
    }

    var requiresApproval: Bool {
        status == .requiresApproval
    }

    func refresh() {
        status = controller.status
    }

    func setEnabled(_ enabled: Bool) {
        isUpdating = true
        defer { isUpdating = false }

        do {
            status = try controller.setEnabled(enabled)
            error = nil
        } catch let error as LaunchAtLoginError {
            self.error = error
            status = controller.status
        } catch {
            self.error = .unavailable
            status = controller.status
        }
    }
}
