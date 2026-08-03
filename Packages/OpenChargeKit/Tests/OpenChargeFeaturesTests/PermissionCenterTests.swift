import OpenChargeCore
@testable import OpenChargeFeatures
import Testing

@Suite("Permission center")
struct PermissionCenterTests {
    @Test
    func queriesProvidersIndependentlyAndIsolatesFailures() async {
        let accessibilityProbe = PermissionProbe()
        let screenRecordingProbe = PermissionProbe()
        let center = PermissionCenter(
            providers: [
                StubPermissionProvider(
                    kind: .accessibility,
                    result: .success(.granted),
                    probe: accessibilityProbe
                ),
                StubPermissionProvider(
                    kind: .screenRecording,
                    result: .failure(.checkFailed),
                    probe: screenRecordingProbe
                )
            ]
        )

        let snapshot = await center.snapshot()

        #expect(snapshot[.accessibility]?.state == .granted)
        #expect(snapshot[.accessibility]?.health == .healthy)
        #expect(
            snapshot[.screenRecording]?.state
                == .unavailable(reasonKey: "permission.screenRecording.checkFailed")
        )
        #expect(
            snapshot[.screenRecording]?.health
                == .failed(
                    messageKey: "permission.screenRecording.checkFailed",
                    recovery: FeatureRecovery(
                        kind: .retry,
                        titleKey: "permission.screenRecording.retry"
                    )
                )
        )
        #expect(await accessibilityProbe.callCount == 1)
        #expect(await screenRecordingProbe.callCount == 1)
    }

    @Test
    func derivesAvailabilityAndHealthWithoutRequestingPermission() async throws {
        let center = PermissionCenter(
            providers: [
                StubPermissionProvider(kind: .accessibility, result: .success(.denied)),
                StubPermissionProvider(kind: .screenRecording, result: .failure(.checkFailed))
            ]
        )
        let descriptor = try featureDescriptor(
            requiredPermissions: [.screenRecording, .accessibility]
        )

        let snapshot = await center.snapshot()
        let evaluation = center.evaluate(
            descriptor: descriptor,
            isEnabled: true,
            snapshot: snapshot
        )

        #expect(
            evaluation.availability
                == .missingPermission(
                    reasonKey: "permission.accessibility.denied",
                    recovery: FeatureRecovery(
                        kind: .openSystemSettings,
                        titleKey: "permission.accessibility.openSettings"
                    )
                )
        )
        #expect(
            evaluation.health
                == .failed(
                    messageKey: "permission.screenRecording.checkFailed",
                    recovery: FeatureRecovery(
                        kind: .retry,
                        titleKey: "permission.screenRecording.retry"
                    )
                )
        )
    }

    @Test
    func disabledFeatureDoesNotRequirePermissionChecks() throws {
        let center = PermissionCenter(providers: [])
        let descriptor = try featureDescriptor(requiredPermissions: [.accessibility])

        let evaluation = center.evaluate(
            descriptor: descriptor,
            isEnabled: false,
            snapshot: PermissionSnapshot(results: [])
        )

        #expect(evaluation.availability == .disabled)
        #expect(evaluation.health == .healthy)
    }

    @Test
    func allGrantedPermissionsProduceAvailableHealthyState() throws {
        let center = PermissionCenter(providers: [])
        let descriptor = try featureDescriptor(
            requiredPermissions: [.accessibility, .screenRecording]
        )
        let snapshot = PermissionSnapshot(
            results: [
                PermissionResult(
                    kind: .accessibility,
                    state: .granted,
                    health: .healthy
                ),
                PermissionResult(
                    kind: .screenRecording,
                    state: .granted,
                    health: .healthy
                )
            ]
        )

        let evaluation = center.evaluate(
            descriptor: descriptor,
            isEnabled: true,
            snapshot: snapshot
        )

        #expect(evaluation.availability == .available)
        #expect(evaluation.health == .healthy)
    }

    @Test
    func missingProviderProducesUnsupportedAndUnhealthyState() throws {
        let center = PermissionCenter(providers: [])
        let descriptor = try featureDescriptor(requiredPermissions: [.finderSync])

        let evaluation = center.evaluate(
            descriptor: descriptor,
            isEnabled: true,
            snapshot: PermissionSnapshot(results: [])
        )

        #expect(
            evaluation.availability
                == .unsupported(reasonKey: "permission.finderSync.providerMissing")
        )
        #expect(
            evaluation.health
                == .failed(
                    messageKey: "permission.finderSync.providerMissing",
                    recovery: nil
                )
        )
    }

    private func featureDescriptor(
        requiredPermissions: Set<PermissionKind>
    ) throws -> FeatureDescriptor {
        try FeatureDescriptor(
            id: #require(FeatureID(rawValue: "foundation.permission-test")),
            category: .foundation,
            titleKey: "feature.permissionTest.title",
            descriptionKey: "feature.permissionTest.description",
            requiredPermissions: requiredPermissions,
            supportsGlobalShortcut: false,
            supportsAppIntent: false
        )
    }
}

private enum StubPermissionError: Error {
    case checkFailed
}

private struct StubPermissionProvider: PermissionProviding {
    let kind: PermissionKind
    let result: Result<PermissionState, StubPermissionError>
    let probe: PermissionProbe

    init(
        kind: PermissionKind,
        result: Result<PermissionState, StubPermissionError>,
        probe: PermissionProbe = PermissionProbe()
    ) {
        self.kind = kind
        self.result = result
        self.probe = probe
    }

    func currentState() async throws -> PermissionState {
        await probe.recordCall()
        return try result.get()
    }
}

private actor PermissionProbe {
    private(set) var callCount = 0

    func recordCall() {
        callCount += 1
    }
}
