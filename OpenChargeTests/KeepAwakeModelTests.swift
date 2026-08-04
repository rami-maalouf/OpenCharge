@testable import OpenCharge
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem
import XCTest

final class KeepAwakeModelTests: XCTestCase {
    @MainActor
    func testLoadRestoresPersistedConfiguration() async {
        var settings = SettingsSchema.default
        settings[.keepAwakeConfiguration] = .string(
            KeepAwakeConfiguration.idleSystemAndDisplay.rawValue
        )
        let store = InMemorySettingsStore(initial: settings)
        let controller = KeepAwakeControllerProbe()
        let model = makeModel(controller: controller, store: store)

        await model.load()

        XCTAssertEqual(model.configuration, .idleSystemAndDisplay)
        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(model.preventsDisplaySleep)
        XCTAssertNil(model.error)
        let appliedConfigurations = await controller.appliedConfigurations
        XCTAssertEqual(appliedConfigurations, [.idleSystemAndDisplay])
    }

    @MainActor
    func testRefreshUsesObservedControllerConfiguration() async {
        let store = InMemorySettingsStore()
        let controller = KeepAwakeControllerProbe(initial: .idleSystem)
        let model = makeModel(controller: controller, store: store)

        await model.refresh()

        XCTAssertEqual(model.configuration, .idleSystem)
        XCTAssertTrue(model.isEnabled)
        XCTAssertFalse(model.preventsDisplaySleep)
    }

    @MainActor
    func testTogglePersistsEnabledAndDisabledConfigurations() async throws {
        let store = InMemorySettingsStore()
        let controller = KeepAwakeControllerProbe()
        let model = makeModel(controller: controller, store: store)

        await model.toggle()

        XCTAssertEqual(model.configuration, .idleSystem)
        var settings = try await store.snapshot()
        XCTAssertEqual(
            settings[.keepAwakeConfiguration],
            .string(KeepAwakeConfiguration.idleSystem.rawValue)
        )

        await model.toggle()

        XCTAssertEqual(model.configuration, .disabled)
        settings = try await store.snapshot()
        XCTAssertEqual(
            settings[.keepAwakeConfiguration],
            .string(KeepAwakeConfiguration.disabled.rawValue)
        )
    }

    @MainActor
    func testConfigurationFailurePreservesStateAndStoredValue() async throws {
        let store = InMemorySettingsStore()
        let controller = KeepAwakeControllerProbe()
        await controller.failNextApply()
        let model = makeModel(controller: controller, store: store)

        await model.setConfiguration(.idleSystemAndDisplay)

        XCTAssertEqual(model.configuration, .disabled)
        XCTAssertEqual(
            model.error,
            .systemFailure(reasonKey: "feature.keepAwake.updateFailed")
        )
        let settings = try await store.snapshot()
        XCTAssertEqual(
            settings[.keepAwakeConfiguration],
            .string(KeepAwakeConfiguration.disabled.rawValue)
        )
    }

    @MainActor
    func testPersistenceFailureRollsBackPowerAssertion() async {
        let controller = KeepAwakeControllerProbe()
        let model = makeModel(
            controller: controller,
            store: FailingKeepAwakeSettingsStore()
        )

        await model.setConfiguration(.idleSystem)

        XCTAssertEqual(model.configuration, .disabled)
        XCTAssertEqual(
            model.error,
            .systemFailure(reasonKey: "feature.keepAwake.settingsUpdateFailed")
        )
        let appliedConfigurations = await controller.appliedConfigurations
        XCTAssertEqual(appliedConfigurations, [.idleSystem, .disabled])
    }

    @MainActor
    func testModelReportsProgressWhileControllerIsApplying() async {
        let store = InMemorySettingsStore()
        let controller = KeepAwakeControllerProbe(blocksNextApply: true)
        let model = makeModel(controller: controller, store: store)
        let update = Task { @MainActor in
            await model.setConfiguration(.idleSystem)
        }

        await controller.waitUntilApplyStarts()
        XCTAssertTrue(model.isUpdating)

        await controller.resumeApply()
        await update.value

        XCTAssertFalse(model.isUpdating)
        XCTAssertEqual(model.configuration, .idleSystem)
    }

    @MainActor
    func testObservesChangesAppliedOutsideThePresentationModel() async {
        let store = InMemorySettingsStore()
        let controller = KeepAwakeControllerProbe()
        let action = KeepAwakeAction(controller: controller)
        let model = KeepAwakeModel(action: action, settingsStore: store)

        _ = await action.set(.idleSystemAndDisplay)
        await waitForModelToObserveAction(model)

        XCTAssertEqual(model.configuration, .idleSystemAndDisplay)
        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(model.preventsDisplaySleep)
    }

    @MainActor
    private func makeModel(
        controller: KeepAwakeControllerProbe,
        store: any SettingsStore
    ) -> KeepAwakeModel {
        KeepAwakeModel(
            action: KeepAwakeAction(controller: controller),
            settingsStore: store
        )
    }

    @MainActor
    private func waitForModelToObserveAction(
        _ model: KeepAwakeModel
    ) async {
        for _ in 0 ..< 20 where model.configuration != .idleSystemAndDisplay {
            await Task.yield()
        }
    }
}

private enum KeepAwakeControllerProbeError: Error {
    case expected
}

private actor KeepAwakeControllerProbe: KeepAwakeControlling {
    private var configuration: KeepAwakeConfiguration
    private var shouldFailNextApply = false
    private var shouldBlockNextApply: Bool
    private var applyContinuation: CheckedContinuation<Void, Never>?
    private var applyStartContinuations: [CheckedContinuation<Void, Never>] = []
    private(set) var appliedConfigurations: [KeepAwakeConfiguration] = []

    init(
        initial: KeepAwakeConfiguration = .disabled,
        blocksNextApply: Bool = false
    ) {
        configuration = initial
        shouldBlockNextApply = blocksNextApply
    }

    func currentConfiguration() -> KeepAwakeConfiguration {
        configuration
    }

    func apply(
        _ configuration: KeepAwakeConfiguration
    ) async throws -> KeepAwakeConfiguration {
        appliedConfigurations.append(configuration)
        if shouldFailNextApply {
            shouldFailNextApply = false
            throw KeepAwakeControllerProbeError.expected
        }
        if shouldBlockNextApply {
            shouldBlockNextApply = false
            await withCheckedContinuation { continuation in
                applyContinuation = continuation
                let startContinuations = applyStartContinuations
                applyStartContinuations.removeAll()
                startContinuations.forEach { $0.resume() }
            }
        }
        self.configuration = configuration
        return configuration
    }

    func failNextApply() {
        shouldFailNextApply = true
    }

    func waitUntilApplyStarts() async {
        if applyContinuation != nil {
            return
        }
        await withCheckedContinuation { continuation in
            applyStartContinuations.append(continuation)
        }
    }

    func resumeApply() {
        applyContinuation?.resume()
        applyContinuation = nil
    }
}

private actor FailingKeepAwakeSettingsStore: SettingsStore {
    func snapshot() throws -> SettingsSchema {
        .default
    }

    func update(
        _: @Sendable (inout SettingsSchema) throws -> Void
    ) throws -> SettingsSchema {
        throw KeepAwakeControllerProbeError.expected
    }
}
