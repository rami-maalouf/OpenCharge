import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Feature state")
struct FeatureStateTests {
    @Test
    func availabilityStatesRemainDistinct() {
        let recovery = FeatureRecovery(
            kind: .openSystemSettings,
            titleKey: "recovery.openPrivacySettings"
        )

        #expect(FeatureAvailability.available != .disabled)
        #expect(FeatureAvailability.unsupported(reasonKey: "reason.unsupported") != .disabled)
        #expect(
            FeatureAvailability.missingPermission(
                reasonKey: "reason.screenRecordingRequired",
                recovery: recovery
            ) != .available
        )
    }

    @Test
    func availabilityRoundTripsWithRecovery() throws {
        let value = FeatureAvailability.missingPermission(
            reasonKey: "reason.accessibilityRequired",
            recovery: FeatureRecovery(
                kind: .openSystemSettings,
                titleKey: "recovery.openAccessibilitySettings"
            )
        )

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(FeatureAvailability.self, from: data)

        #expect(decoded == value)
    }

    @Test
    func healthCarriesTypedRecovery() {
        let health = FeatureHealth.failed(
            messageKey: "health.powerAssertionFailed",
            recovery: FeatureRecovery(kind: .retry, titleKey: "recovery.retry")
        )

        #expect(health.isHealthy == false)
        #expect(health.recovery?.kind == .retry)
        #expect(FeatureHealth.healthy.isHealthy)
    }
}
