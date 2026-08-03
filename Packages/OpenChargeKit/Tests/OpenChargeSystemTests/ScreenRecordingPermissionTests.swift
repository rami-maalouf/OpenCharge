import Foundation
import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("Screen recording permission")
struct ScreenRecordingPermissionTests {
    @Test
    func statusCheckUsesPreflightWithoutRequesting() async {
        let probe = ScreenRecordingProbe(preflightResult: false, requestResult: true)
        let provider = ScreenRecordingPermissionProvider(
            preflight: probe.preflight,
            request: probe.request
        )

        let state = await provider.currentState()

        #expect(state == .denied)
        #expect(probe.preflightCallCount == 1)
        #expect(probe.requestCallCount == 0)
    }

    @Test
    func statusCheckReportsGrantedAccess() async {
        let probe = ScreenRecordingProbe(preflightResult: true, requestResult: false)
        let provider = ScreenRecordingPermissionProvider(
            preflight: probe.preflight,
            request: probe.request
        )

        let state = await provider.currentState()

        #expect(state == .granted)
        #expect(probe.preflightCallCount == 1)
        #expect(probe.requestCallCount == 0)
    }

    @Test(arguments: [(true, PermissionState.granted), (false, PermissionState.denied)])
    func explicitRequestMapsObservedResult(
        granted: Bool,
        expectedState: PermissionState
    ) async {
        let probe = ScreenRecordingProbe(preflightResult: false, requestResult: granted)
        let provider = ScreenRecordingPermissionProvider(
            preflight: probe.preflight,
            request: probe.request
        )

        let state = await provider.requestAccess()

        #expect(state == expectedState)
        #expect(probe.preflightCallCount == 0)
        #expect(probe.requestCallCount == 1)
    }

    @Test
    func exposesMacOS26ScreenRecordingRecoveryRoute() {
        #expect(
            ScreenRecordingPermissionProvider.recoveryURL.absoluteString
                == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        )
    }
}

private final class ScreenRecordingProbe: @unchecked Sendable {
    private let lock = NSLock()
    private let preflightResult: Bool
    private let requestResult: Bool
    private var storedPreflightCallCount = 0
    private var storedRequestCallCount = 0

    init(preflightResult: Bool, requestResult: Bool) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
    }

    var preflightCallCount: Int {
        lock.withLock { storedPreflightCallCount }
    }

    var requestCallCount: Int {
        lock.withLock { storedRequestCallCount }
    }

    func preflight() -> Bool {
        lock.withLock {
            storedPreflightCallCount += 1
        }
        return preflightResult
    }

    func request() -> Bool {
        lock.withLock {
            storedRequestCallCount += 1
        }
        return requestResult
    }
}
