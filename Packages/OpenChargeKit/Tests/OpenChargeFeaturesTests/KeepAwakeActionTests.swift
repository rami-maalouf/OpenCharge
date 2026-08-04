import OpenChargeCore
@testable import OpenChargeFeatures
import Testing

@Suite("Keep Awake action")
struct KeepAwakeActionTests {
    @Test
    func modesExposeExactAssertionRequirements() {
        #expect(!KeepAwakeConfiguration.disabled.isEnabled)
        #expect(!KeepAwakeConfiguration.disabled.preventsIdleSystemSleep)
        #expect(!KeepAwakeConfiguration.disabled.preventsDisplaySleep)

        #expect(KeepAwakeConfiguration.idleSystem.isEnabled)
        #expect(KeepAwakeConfiguration.idleSystem.preventsIdleSystemSleep)
        #expect(!KeepAwakeConfiguration.idleSystem.preventsDisplaySleep)

        #expect(KeepAwakeConfiguration.idleSystemAndDisplay.isEnabled)
        #expect(KeepAwakeConfiguration.idleSystemAndDisplay.preventsIdleSystemSleep)
        #expect(KeepAwakeConfiguration.idleSystemAndDisplay.preventsDisplaySleep)
    }

    @Test
    func appliesIdleAndDisplayModesAndExposesObservedState() async {
        let controller = KeepAwakeControllerProbe()
        let action = KeepAwakeAction(controller: controller)

        let idleResult = await action.set(.idleSystem)
        let displayResult = await action.set(.idleSystemAndDisplay)

        #expect(
            idleResult
                == .success(KeepAwakeState(configuration: .idleSystem))
        )
        #expect(
            displayResult
                == .success(KeepAwakeState(configuration: .idleSystemAndDisplay))
        )
        #expect(
            await controller.appliedConfigurations
                == [.idleSystem, .idleSystemAndDisplay]
        )
        #expect(
            await action.currentState()
                == KeepAwakeState(configuration: .idleSystemAndDisplay)
        )
    }

    @Test
    func repeatedConfigurationIsIdempotent() async {
        let controller = KeepAwakeControllerProbe(initial: .idleSystem)
        let action = KeepAwakeAction(
            controller: controller,
            initialConfiguration: .idleSystem
        )

        let result = await action.set(.idleSystem)

        #expect(result == .success(KeepAwakeState(configuration: .idleSystem)))
        #expect(await controller.appliedConfigurations.isEmpty)
    }

    @Test
    func controllerFailurePreservesPreviousActionState() async {
        let controller = KeepAwakeControllerProbe(initial: .idleSystem)
        await controller.failNextApply()
        let action = KeepAwakeAction(
            controller: controller,
            initialConfiguration: .idleSystem
        )

        let result = await action.set(.idleSystemAndDisplay)

        #expect(
            result
                == .failure(
                    .systemFailure(reasonKey: "feature.keepAwake.updateFailed")
                )
        )
        #expect(
            await action.currentState()
                == KeepAwakeState(configuration: .idleSystem)
        )
    }

    @Test
    func refreshReadsControllerWithoutChangingAssertions() async {
        let controller = KeepAwakeControllerProbe(initial: .idleSystemAndDisplay)
        let action = KeepAwakeAction(controller: controller)

        let state = await action.refresh()

        #expect(state == KeepAwakeState(configuration: .idleSystemAndDisplay))
        #expect(await controller.appliedConfigurations.isEmpty)
    }

    @Test
    func stateUpdatesIncludeCurrentAndExternallyAppliedState() async {
        let controller = KeepAwakeControllerProbe()
        let action = KeepAwakeAction(controller: controller)
        let updates = await action.stateUpdates()
        var iterator = updates.makeAsyncIterator()

        let initialState = await iterator.next()
        _ = await action.set(.idleSystemAndDisplay)
        let updatedState = await iterator.next()

        #expect(initialState == KeepAwakeState(configuration: .disabled))
        #expect(
            updatedState
                == KeepAwakeState(configuration: .idleSystemAndDisplay)
        )
    }
}

private enum KeepAwakeProbeError: Error {
    case expected
}

private actor KeepAwakeControllerProbe: KeepAwakeControlling {
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
            throw KeepAwakeProbeError.expected
        }
        self.configuration = configuration
        return configuration
    }

    func failNextApply() {
        shouldFailNextApply = true
    }
}
