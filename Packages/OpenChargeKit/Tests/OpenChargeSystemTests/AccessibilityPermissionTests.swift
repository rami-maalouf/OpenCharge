import Foundation
import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("Accessibility permission")
struct AccessibilityPermissionTests {
    @Test
    func statusCheckNeverUsesPromptPath() async {
        let probe = AccessibilityProbe(checkResult: false, requestResult: true)
        let provider = AccessibilityPermissionProvider(
            checkTrust: probe.checkTrust,
            requestTrust: probe.requestTrust
        )

        let state = await provider.currentState()

        #expect(state == .denied)
        #expect(probe.checkCallCount == 1)
        #expect(probe.requestCallCount == 0)
    }

    @Test
    func statusCheckReportsGrantedTrust() async {
        let probe = AccessibilityProbe(checkResult: true, requestResult: false)
        let provider = AccessibilityPermissionProvider(
            checkTrust: probe.checkTrust,
            requestTrust: probe.requestTrust
        )

        let state = await provider.currentState()

        #expect(state == .granted)
        #expect(probe.checkCallCount == 1)
        #expect(probe.requestCallCount == 0)
    }

    @Test(arguments: [(true, PermissionState.granted), (false, PermissionState.denied)])
    func explicitRequestReturnsRecoverableObservedState(
        trusted: Bool,
        expectedState: PermissionState
    ) async {
        let probe = AccessibilityProbe(checkResult: false, requestResult: trusted)
        let provider = AccessibilityPermissionProvider(
            checkTrust: probe.checkTrust,
            requestTrust: probe.requestTrust
        )

        let state = await provider.requestAccess()

        #expect(state == expectedState)
        #expect(probe.checkCallCount == 0)
        #expect(probe.requestCallCount == 1)
        #expect(provider.recovery.kind == .openSystemSettings)
        #expect(provider.recovery.titleKey == "permission.accessibility.openSettings")
    }

    @Test
    func exposesMacOS26AccessibilityRecoveryRoute() {
        #expect(
            AccessibilityPermissionProvider.recoveryURL.absoluteString
                == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        )
    }
}

private final class AccessibilityProbe: @unchecked Sendable {
    private let lock = NSLock()
    private let checkResult: Bool
    private let requestResult: Bool
    private var storedCheckCallCount = 0
    private var storedRequestCallCount = 0

    init(checkResult: Bool, requestResult: Bool) {
        self.checkResult = checkResult
        self.requestResult = requestResult
    }

    var checkCallCount: Int {
        lock.withLock { storedCheckCallCount }
    }

    var requestCallCount: Int {
        lock.withLock { storedRequestCallCount }
    }

    func checkTrust() -> Bool {
        lock.withLock {
            storedCheckCallCount += 1
        }
        return checkResult
    }

    func requestTrust() -> Bool {
        lock.withLock {
            storedRequestCallCount += 1
        }
        return requestResult
    }
}
