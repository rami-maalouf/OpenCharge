@testable import OpenCharge
import OpenChargeCore
import OpenChargeSystem
import XCTest

final class PermissionsModelTests: XCTestCase {
    @MainActor
    func testConstructionChecksNothingAndExplicitRefreshReadsState() async {
        let probe = PermissionProbe(states: [.denied])
        let model = PermissionsModel(
            capabilities: [capability(probe: probe)]
        )

        let initialCheckCount = await probe.checkCount
        XCTAssertEqual(initialCheckCount, 0)

        await model.refresh()

        let refreshedCheckCount = await probe.checkCount
        XCTAssertEqual(refreshedCheckCount, 1)
        XCTAssertEqual(model.diagnostics.first?.state, .denied)
        let requestCount = await probe.requestCount
        XCTAssertEqual(requestCount, 0)
    }

    @MainActor
    func testAppActivationRefreshesPermissionState() async {
        let probe = PermissionProbe(states: [.denied, .granted])
        let dependencies = AppDependencies(
            registry: FeatureRegistry(factories: []),
            settingsStore: InMemorySettingsStore(),
            hasPersistentSettings: false,
            permissionCapabilities: [capability(probe: probe)]
        )
        let appModel = AppModel(dependencies: dependencies)

        await appModel.refreshPermissions()
        XCTAssertEqual(appModel.permissions.diagnostics.first?.state, .denied)

        await appModel.didBecomeActive()

        XCTAssertEqual(appModel.permissions.diagnostics.first?.state, .granted)
        let checkCount = await probe.checkCount
        XCTAssertEqual(checkCount, 2)
    }

    @MainActor
    func testRequestAndRecoveryRunOnlyAfterExplicitActions() async {
        let probe = PermissionProbe(states: [.notDetermined])
        let recovery = RecoveryProbe()
        let model = PermissionsModel(
            capabilities: [capability(probe: probe, recovery: recovery)]
        )

        await model.refresh()
        let initialRequestCount = await probe.requestCount
        XCTAssertEqual(initialRequestCount, 0)
        XCTAssertEqual(recovery.callCount, 0)

        await model.requestAccess(for: .screenRecording)
        model.openRecovery(for: .screenRecording)

        let requestCount = await probe.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(recovery.callCount, 1)
        XCTAssertEqual(model.diagnostics.first?.state, .granted)
    }

    @MainActor
    private func capability(
        probe: PermissionProbe,
        recovery: RecoveryProbe = RecoveryProbe()
    ) -> PermissionCapability {
        PermissionCapability(
            kind: .screenRecording,
            title: "Screen Recording",
            explanation: "Test explanation",
            checkState: { await probe.check() },
            requestAccess: { await probe.request() },
            recoveryTitle: "Open Settings",
            recover: { recovery.perform() }
        )
    }
}

private actor PermissionProbe {
    private var states: [PermissionState]
    private(set) var checkCount = 0
    private(set) var requestCount = 0

    init(states: [PermissionState]) {
        self.states = states
    }

    func check() -> PermissionState {
        checkCount += 1
        guard !states.isEmpty else {
            return .unavailable(reasonKey: "permission.test.exhausted")
        }
        if states.count == 1 {
            return states[0]
        }
        return states.removeFirst()
    }

    func request() -> PermissionState {
        requestCount += 1
        return .granted
    }
}

@MainActor
private final class RecoveryProbe {
    private(set) var callCount = 0

    func perform() {
        callCount += 1
    }
}
