import Foundation

public struct ActionRequest<Input: Hashable & Codable & Sendable>: Hashable, Codable, Sendable {
    public let id: UUID
    public let featureID: FeatureID
    public let input: Input

    public init(id: UUID, featureID: FeatureID, input: Input) {
        self.id = id
        self.featureID = featureID
        self.input = input
    }
}

public protocol ActionCancellationChecking: Sendable {
    func isCancelled() async -> Bool
}
