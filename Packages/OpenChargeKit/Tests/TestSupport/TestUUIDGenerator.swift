import Foundation

public enum TestUUIDGeneratorError: Error, Equatable, Sendable {
    case exhausted
}

public actor TestUUIDGenerator {
    private let values: [UUID]
    private var nextIndex = 0

    public init(values: [UUID]) {
        self.values = values
    }

    public func next() throws -> UUID {
        guard values.indices.contains(nextIndex) else {
            throw TestUUIDGeneratorError.exhausted
        }

        defer { nextIndex += 1 }
        return values[nextIndex]
    }
}
