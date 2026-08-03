@testable import OpenCharge
import OpenChargeCore
import OpenChargeSystem
import XCTest

@MainActor
final class FinderSettingsModelTests: XCTestCase {
    func testLoadReadsSharedEnablementAndExtensionStatus() async throws {
        let featureID = try XCTUnwrap(
            FeatureID(rawValue: "finder.copy-path")
        )
        var settings = SettingsSchema.default
        settings.setFeature(featureID, enabled: true)
        let store = InMemorySettingsStore(initial: settings)
        let expectedStatus = FinderExtensionStatus(
            installation: .installed,
            activation: .disabled
        )
        let model = FinderSettingsModel(
            settingsStore: store,
            capability: capability(status: expectedStatus)
        )

        await model.load()

        XCTAssertTrue(model.isCopyPathEnabled)
        XCTAssertEqual(model.extensionStatus, expectedStatus)
        XCTAssertNil(model.settingsError)
    }

    func testEnablementPersistsThroughSharedSettingsStore() async throws {
        let featureID = try XCTUnwrap(
            FeatureID(rawValue: "finder.copy-path")
        )
        let store = InMemorySettingsStore()
        let model = FinderSettingsModel(
            settingsStore: store,
            capability: capability(
                status: FinderExtensionStatus(
                    installation: .installed,
                    activation: .enabled
                )
            )
        )

        await model.setCopyPathEnabled(true)

        XCTAssertTrue(model.isCopyPathEnabled)
        let settings = try await store.snapshot()
        XCTAssertTrue(settings.isFeatureEnabled(featureID))
    }

    func testStatusRefreshDoesNotChangeFeatureEnablement() async {
        let statusProbe = FinderStatusProbe()
        let store = InMemorySettingsStore()
        let model = FinderSettingsModel(
            settingsStore: store,
            capability: FinderExtensionCapability(
                currentStatus: { await statusProbe.status() },
                openManagement: {}
            )
        )
        await model.load()
        await model.setCopyPathEnabled(true)
        await statusProbe.setEnabled(true)

        await model.refreshStatus()

        XCTAssertTrue(model.isCopyPathEnabled)
        XCTAssertEqual(model.extensionStatus?.activation, .enabled)
    }

    func testRepeatedLoadDoesNotRepeatInitialization() async {
        let statusProbe = CountingFinderStatusProbe()
        let store = InMemorySettingsStore()
        let model = FinderSettingsModel(
            settingsStore: store,
            capability: FinderExtensionCapability(
                currentStatus: { await statusProbe.status() },
                openManagement: {}
            )
        )
        await model.load()

        await model.load()

        let callCount = await statusProbe.callCount()
        XCTAssertEqual(callCount, 1)
    }

    private func capability(
        status: FinderExtensionStatus
    ) -> FinderExtensionCapability {
        FinderExtensionCapability(
            currentStatus: { status },
            openManagement: {}
        )
    }
}

private actor FinderStatusProbe {
    private var isEnabled = false

    func status() -> FinderExtensionStatus {
        FinderExtensionStatus(
            installation: .installed,
            activation: isEnabled ? .enabled : .disabled
        )
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

private actor CountingFinderStatusProbe {
    private var calls = 0

    func status() -> FinderExtensionStatus {
        calls += 1
        return FinderExtensionStatus(
            installation: .installed,
            activation: .enabled
        )
    }

    func callCount() -> Int {
        calls
    }
}
