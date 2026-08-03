public struct FeatureFactory: Sendable {
    public let id: FeatureID
    private let make: @Sendable () throws -> FeatureDescriptor

    public init(
        id: FeatureID,
        make: @escaping @Sendable () throws -> FeatureDescriptor
    ) {
        self.id = id
        self.make = make
    }

    fileprivate func makeDescriptor() throws -> FeatureDescriptor {
        try make()
    }
}

public enum FeatureRegistryIssue: Error, Hashable, Codable, Sendable {
    case duplicateIdentifier(id: FeatureID)
    case factoryFailed(id: FeatureID)
    case identifierMismatch(expected: FeatureID, actual: FeatureID)
}

public struct FeatureRegistry: Sendable {
    public let descriptors: [FeatureDescriptor]
    public let issues: [FeatureRegistryIssue]

    public init(factories: [FeatureFactory]) {
        let factoriesByID = Dictionary(grouping: factories, by: \.id)
        var descriptors: [FeatureDescriptor] = []
        var issues: [FeatureRegistryIssue] = []

        for id in factoriesByID.keys.sorted() {
            guard let matchingFactories = factoriesByID[id] else {
                continue
            }
            guard matchingFactories.count == 1 else {
                issues.append(.duplicateIdentifier(id: id))
                continue
            }

            do {
                let descriptor = try matchingFactories[0].makeDescriptor()
                guard descriptor.id == id else {
                    issues.append(.identifierMismatch(expected: id, actual: descriptor.id))
                    continue
                }
                descriptors.append(descriptor)
            } catch {
                issues.append(.factoryFailed(id: id))
            }
        }

        self.descriptors = descriptors
        self.issues = issues
    }

    public func descriptor(for id: FeatureID) -> FeatureDescriptor? {
        descriptors.first { $0.id == id }
    }
}
