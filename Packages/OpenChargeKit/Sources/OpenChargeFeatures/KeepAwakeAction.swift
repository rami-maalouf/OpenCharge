import Foundation
import OpenChargeCore

public actor KeepAwakeAction {
    private let controller: any KeepAwakeControlling
    private var stateObservers: [
        UUID: AsyncStream<KeepAwakeState>.Continuation
    ] = [:]
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

    public func stateUpdates() -> AsyncStream<KeepAwakeState> {
        let observerID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: KeepAwakeState.self
        )
        stateObservers[observerID] = continuation
        continuation.yield(state)
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeStateObserver(observerID)
            }
        }
        return stream
    }

    @discardableResult
    public func refresh() async -> KeepAwakeState {
        let configuration = await controller.currentConfiguration()
        let observedState = KeepAwakeState(configuration: configuration)
        state = observedState
        notifyStateObservers()
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
            notifyStateObservers()
            return .success(observedState)
        } catch {
            return .failure(
                .systemFailure(reasonKey: "feature.keepAwake.updateFailed")
            )
        }
    }

    private func notifyStateObservers() {
        for continuation in stateObservers.values {
            continuation.yield(state)
        }
    }

    private func removeStateObserver(_ observerID: UUID) {
        stateObservers[observerID] = nil
    }
}
