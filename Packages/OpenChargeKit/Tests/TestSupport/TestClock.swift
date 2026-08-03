import OpenChargeCore

public enum TestClockError: Error, Equatable, Sendable {
    case negativeAdvance
}

public actor TestClock {
    public private(set) var now: Duration

    public init(now: Duration = .zero) {
        self.now = now
    }

    public func advance(by duration: Duration) throws {
        guard duration >= .zero else {
            throw TestClockError.negativeAdvance
        }
        now += duration
    }
}

public actor TestCancellation: ActionCancellationChecking {
    private var cancelled = false

    public init() {}

    public func cancel() {
        cancelled = true
    }

    public func isCancelled() -> Bool {
        cancelled
    }
}
