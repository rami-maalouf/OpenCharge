import Observation
import OpenChargeCore
import OpenChargeFeatures

@MainActor
@Observable
final class KeepAwakeModel {
    private let action: KeepAwakeAction
    private let settingsStore: any SettingsStore
    private var lastEnabledConfiguration = KeepAwakeConfiguration.idleSystem
    private var lastRequestedConfiguration: KeepAwakeConfiguration?

    private(set) var error: ActionError?
    private(set) var isUpdating = false
    private(set) var state = KeepAwakeState(configuration: .disabled)

    init(
        action: KeepAwakeAction,
        settingsStore: any SettingsStore
    ) {
        self.action = action
        self.settingsStore = settingsStore
    }

    var configuration: KeepAwakeConfiguration {
        state.configuration
    }

    var isEnabled: Bool {
        state.isEnabled
    }

    var preventsDisplaySleep: Bool {
        state.preventsDisplaySleep
    }

    func load() async {
        guard beginUpdate() else {
            return
        }
        defer { isUpdating = false }

        do {
            let settings = try await settingsStore.snapshot()
            let savedConfiguration = try Self.configuration(from: settings)
            state = await action.refresh()
            await applyWithoutPersistence(savedConfiguration)
        } catch {
            self.error = .systemFailure(
                reasonKey: "feature.keepAwake.settingsLoadFailed"
            )
        }
    }

    func refresh() async {
        guard beginUpdate() else {
            return
        }
        defer { isUpdating = false }

        state = await action.refresh()
        rememberEnabledConfiguration(state.configuration)
        error = nil
    }

    func toggle() async {
        let target = isEnabled ? .disabled : lastEnabledConfiguration
        await setConfiguration(target)
    }

    func setConfiguration(_ configuration: KeepAwakeConfiguration) async {
        guard beginUpdate() else {
            return
        }
        defer { isUpdating = false }
        lastRequestedConfiguration = configuration

        let previousState = state
        switch await action.set(configuration) {
        case let .success(observedState):
            state = observedState
            do {
                try await persist(observedState.configuration)
                rememberEnabledConfiguration(observedState.configuration)
                error = nil
            } catch {
                await rollBack(to: previousState)
                self.error = .systemFailure(
                    reasonKey: "feature.keepAwake.settingsUpdateFailed"
                )
            }
        case let .failure(actionError):
            error = actionError
            state = await action.currentState()
        case .cancelled:
            error = .cancelled
            state = await action.currentState()
        case let .partialSuccess(successes, failures):
            error = .partialSuccess(
                succeededCount: successes.count,
                failedCount: failures.count,
                reasonKey: "feature.keepAwake.partialUpdate"
            )
            state = await action.currentState()
        }
    }

    func retry() async {
        if let lastRequestedConfiguration {
            await setConfiguration(lastRequestedConfiguration)
        } else {
            await load()
        }
    }

    private func beginUpdate() -> Bool {
        guard !isUpdating else {
            return false
        }
        isUpdating = true
        return true
    }

    private func applyWithoutPersistence(
        _ configuration: KeepAwakeConfiguration
    ) async {
        switch await action.set(configuration) {
        case let .success(observedState):
            state = observedState
            rememberEnabledConfiguration(observedState.configuration)
            error = nil
        case let .failure(actionError):
            error = actionError
            state = await action.currentState()
        case .cancelled:
            error = .cancelled
            state = await action.currentState()
        case let .partialSuccess(successes, failures):
            error = .partialSuccess(
                succeededCount: successes.count,
                failedCount: failures.count,
                reasonKey: "feature.keepAwake.partialUpdate"
            )
            state = await action.currentState()
        }
    }

    private func persist(
        _ configuration: KeepAwakeConfiguration
    ) async throws {
        try await settingsStore.update { settings in
            settings[.keepAwakeConfiguration] = .string(configuration.rawValue)
        }
    }

    private func rollBack(to previousState: KeepAwakeState) async {
        switch await action.set(previousState.configuration) {
        case let .success(observedState):
            state = observedState
        case .cancelled, .failure, .partialSuccess:
            state = await action.currentState()
        }
    }

    private func rememberEnabledConfiguration(
        _ configuration: KeepAwakeConfiguration
    ) {
        guard configuration.isEnabled else {
            return
        }
        lastEnabledConfiguration = configuration
    }

    private static func configuration(
        from settings: SettingsSchema
    ) throws -> KeepAwakeConfiguration {
        guard case let .string(rawValue)? = settings[.keepAwakeConfiguration],
              let configuration = KeepAwakeConfiguration(rawValue: rawValue)
        else {
            throw KeepAwakeModelError.invalidConfiguration
        }
        return configuration
    }
}

private enum KeepAwakeModelError: Error {
    case invalidConfiguration
}
