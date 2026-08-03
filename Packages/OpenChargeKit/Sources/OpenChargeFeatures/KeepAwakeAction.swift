import OpenChargeCore

public actor KeepAwakeAction {
    private let controller: any KeepAwakeControlling
    private var state: KeepAwakeState

    public init(
        controller: any KeepAwakeControlling,
        initialConfiguration: KeepAwakeConfiguration = .disabled
    ) {
        self.controller = controller
        state = KeepAwakeState(configuration: initialConfiguration)
    }

    public func currentState() -> KeepAwakeState {
        state
    }

    @discardableResult
    public func refresh() async -> KeepAwakeState {
        let configuration = await controller.currentConfiguration()
        let observedState = KeepAwakeState(configuration: configuration)
        state = observedState
        return observedState
    }

    public func set(
        _ configuration: KeepAwakeConfiguration
    ) async -> ActionResult<KeepAwakeState> {
        guard configuration != state.configuration else {
            return .success(state)
        }

        do {
            let observedConfiguration = try await controller.apply(configuration)
            let observedState = KeepAwakeState(configuration: observedConfiguration)
            state = observedState
            return .success(observedState)
        } catch {
            return .failure(
                .systemFailure(reasonKey: "feature.keepAwake.updateFailed")
            )
        }
    }
}
