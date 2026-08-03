@testable import OpenCharge
import OpenChargeCore
import OpenChargeFeatures
import XCTest

final class KeepAwakeIntentTests: XCTestCase {
    func testGetRefreshesTheInjectedFeatureAction() async throws {
        let controller = KeepAwakeIntentControllerProbe(
            initial: .idleSystemAndDisplay
        )
        let action = KeepAwakeAction(controller: controller)
        let intent = GetKeepAwakeIntent(action: action)

        let result = try await intent.perform()
        let currentState = await action.currentState()
        let appliedConfigurations = await controller.appliedConfigurations

        XCTAssertEqual(result.value, .systemAndDisplaySleep)
        XCTAssertEqual(
            currentState,
            KeepAwakeState(configuration: .idleSystemAndDisplay)
        )
        XCTAssertEqual(appliedConfigurations, [])
    }

    func testSetUsesTheInjectedFeatureAction() async throws {
        let controller = KeepAwakeIntentControllerProbe()
        let action = KeepAwakeAction(controller: controller)
        let intent = SetKeepAwakeIntent(
            mode: .systemSleep,
            action: action
        )

        let result = try await intent.perform()
        let currentState = await action.currentState()
        let appliedConfigurations = await controller.appliedConfigurations

        XCTAssertEqual(result.value, .systemSleep)
        XCTAssertEqual(
            currentState,
            KeepAwakeState(configuration: .idleSystem)
        )
        XCTAssertEqual(appliedConfigurations, [.idleSystem])
    }

    func testSetFailureReturnsTheObservedMode() async throws {
        let controller = KeepAwakeIntentControllerProbe(initial: .idleSystem)
        await controller.failNextApply()
        let action = KeepAwakeAction(
            controller: controller,
            initialConfiguration: .idleSystem
        )
        let intent = SetKeepAwakeIntent(
            mode: .systemAndDisplaySleep,
            action: action
        )

        let result = try await intent.perform()
        let currentState = await action.currentState()

        XCTAssertEqual(result.value, .systemSleep)
        XCTAssertEqual(
            currentState,
            KeepAwakeState(configuration: .idleSystem)
        )
    }
}

private enum KeepAwakeIntentControllerProbeError: Error {
    case expected
}

private actor KeepAwakeIntentControllerProbe: KeepAwakeControlling {
    private var configuration: KeepAwakeConfiguration
    private var shouldFailNextApply = false
    private(set) var appliedConfigurations: [KeepAwakeConfiguration] = []

    init(initial: KeepAwakeConfiguration = .disabled) {
        configuration = initial
    }

    func currentConfiguration() -> KeepAwakeConfiguration {
        configuration
    }

    func apply(
        _ configuration: KeepAwakeConfiguration
    ) throws -> KeepAwakeConfiguration {
        appliedConfigurations.append(configuration)
        if shouldFailNextApply {
            shouldFailNextApply = false
            throw KeepAwakeIntentControllerProbeError.expected
        }
        self.configuration = configuration
        return configuration
    }

    func failNextApply() {
        shouldFailNextApply = true
    }
}
