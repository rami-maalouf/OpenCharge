@testable import OpenCharge
import OpenChargeCore
import XCTest

final class FeatureRowModelTests: XCTestCase {
    @MainActor
    func testExposesDescriptorAndEnabledState() throws {
        let descriptor = try makeDescriptor()
        let model = FeatureRowModel(
            descriptor: descriptor,
            isEnabled: true,
            availability: .available,
            health: .healthy
        )

        XCTAssertEqual(model.id, descriptor.id)
        XCTAssertEqual(model.titleKey, descriptor.titleKey)
        XCTAssertEqual(model.descriptionKey, descriptor.descriptionKey)
        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(model.canChangeEnablement)
        XCTAssertNil(model.recovery)
    }

    @MainActor
    func testMissingPermissionProvidesAvailabilityRecovery() throws {
        let availabilityRecovery = FeatureRecovery(
            kind: .openSystemSettings,
            titleKey: "recovery.openAccessibilitySettings"
        )
        let healthRecovery = FeatureRecovery(kind: .retry, titleKey: "recovery.retry")
        let model = try FeatureRowModel(
            descriptor: makeDescriptor(),
            isEnabled: true,
            availability: .missingPermission(
                reasonKey: "permission.accessibility.required",
                recovery: availabilityRecovery
            ),
            health: .failed(messageKey: "health.failed", recovery: healthRecovery)
        )

        XCTAssertEqual(model.recovery, availabilityRecovery)
        XCTAssertEqual(model.availabilityMessageKey, "permission.accessibility.required")
        XCTAssertEqual(model.healthMessageKey, "health.failed")
    }

    @MainActor
    func testHealthRecoveryIsUsedWhenAvailabilityHasNone() throws {
        let recovery = FeatureRecovery(kind: .retry, titleKey: "recovery.retry")
        let model = try FeatureRowModel(
            descriptor: makeDescriptor(),
            isEnabled: true,
            availability: .available,
            health: .degraded(messageKey: "health.degraded", recovery: recovery)
        )

        XCTAssertEqual(model.recovery, recovery)
    }

    @MainActor
    func testUnsupportedFeatureCannotBeEnabled() throws {
        let model = try FeatureRowModel(
            descriptor: makeDescriptor(),
            isEnabled: false,
            availability: .unsupported(reasonKey: "availability.unsupported"),
            health: .healthy
        )

        XCTAssertFalse(model.canChangeEnablement)
        XCTAssertEqual(model.availabilityMessageKey, "availability.unsupported")
    }
}

private func makeDescriptor() throws -> FeatureDescriptor {
    let id = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
    return FeatureDescriptor(
        id: id,
        category: .foundation,
        titleKey: "feature.keepAwake.title",
        descriptionKey: "feature.keepAwake.description",
        supportsGlobalShortcut: true,
        supportsAppIntent: true
    )
}
