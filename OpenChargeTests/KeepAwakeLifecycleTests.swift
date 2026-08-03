@testable import OpenCharge
import OpenChargeCore
import OpenChargeFeatures
import XCTest

final class KeepAwakeLifecycleTests: XCTestCase {
    func testRepeatedTransitionsAndTerminationLeaveNoActiveHandles() async {
        let controller = LifecycleKeepAwakeControllerProbe()
        let action = KeepAwakeAction(controller: controller)
        let lifecycle = AppLifecycleController(keepAwakeAction: action)

        _ = await action.set(.idleSystem)
        _ = await action.set(.idleSystem)
        _ = await action.set(.idleSystemAndDisplay)
        _ = await action.set(.disabled)
        _ = await action.set(.idleSystemAndDisplay)

        async let firstCleanup: Void = lifecycle.prepareForTermination()
        async let secondCleanup: Void = lifecycle.prepareForTermination()
        _ = await (firstCleanup, secondCleanup)

        let configuration = await controller.currentConfiguration()
        let activeHandleCount = await controller.activeHandleCount
        let appliedConfigurations = await controller.appliedConfigurations
        XCTAssertEqual(configuration, .disabled)
        XCTAssertEqual(activeHandleCount, 0)
        XCTAssertEqual(
            appliedConfigurations,
            [
                .idleSystem,
                .idleSystemAndDisplay,
                .disabled,
                .idleSystemAndDisplay,
                .disabled
            ]
        )
    }

    func testTerminationRetriesOneTransientReleaseFailure() async {
        let controller = LifecycleKeepAwakeControllerProbe(
            failedDisableAttempts: 1
        )
        let action = KeepAwakeAction(controller: controller)
        let lifecycle = AppLifecycleController(keepAwakeAction: action)
        _ = await action.set(.idleSystemAndDisplay)

        await lifecycle.prepareForTermination()

        let configuration = await controller.currentConfiguration()
        let activeHandleCount = await controller.activeHandleCount
        let disableAttemptCount = await controller.disableAttemptCount
        XCTAssertEqual(configuration, .disabled)
        XCTAssertEqual(activeHandleCount, 0)
        XCTAssertEqual(disableAttemptCount, 2)
    }
}

private enum LifecycleKeepAwakeControllerProbeError: Error {
    case expected
}

private actor LifecycleKeepAwakeControllerProbe: KeepAwakeControlling {
    private enum Handle: Hashable {
        case display
        case idleSystem
    }

    private var activeHandles: Set<Handle> = []
    private var configuration = KeepAwakeConfiguration.disabled
    private var failedDisableAttempts: Int
    private(set) var appliedConfigurations: [KeepAwakeConfiguration] = []
    private(set) var disableAttemptCount = 0

    init(failedDisableAttempts: Int = 0) {
        self.failedDisableAttempts = failedDisableAttempts
    }

    var activeHandleCount: Int {
        activeHandles.count
    }

    func currentConfiguration() -> KeepAwakeConfiguration {
        configuration
    }

    func apply(
        _ configuration: KeepAwakeConfiguration
    ) throws -> KeepAwakeConfiguration {
        appliedConfigurations.append(configuration)
        if configuration == .disabled {
            disableAttemptCount += 1
            if failedDisableAttempts > 0 {
                failedDisableAttempts -= 1
                throw LifecycleKeepAwakeControllerProbeError.expected
            }
        }

        activeHandles = switch configuration {
        case .disabled:
            []
        case .idleSystem:
            [.idleSystem]
        case .idleSystemAndDisplay:
            [.idleSystem, .display]
        }
        self.configuration = configuration
        return configuration
    }
}
