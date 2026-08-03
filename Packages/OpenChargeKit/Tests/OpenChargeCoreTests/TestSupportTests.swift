import Foundation
@testable import OpenChargeCore
import Testing
import TestSupport

@Suite("Test support")
struct TestSupportTests {
    @Test
    func clockAdvancesOnlyWhenControlled() async throws {
        let clock = TestClock(now: .seconds(10))

        try await clock.advance(by: .seconds(5))

        #expect(await clock.now == .seconds(15))
        await #expect(throws: TestClockError.negativeAdvance) {
            try await clock.advance(by: .seconds(-1))
        }
    }

    @Test
    func uuidGeneratorReturnsValuesInOrderThenExhausts() async throws {
        let first = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let second = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let generator = TestUUIDGenerator(values: [first, second])

        #expect(try await generator.next() == first)
        #expect(try await generator.next() == second)
        await #expect(throws: TestUUIDGeneratorError.exhausted) {
            try await generator.next()
        }
    }

    @Test
    func cancellationChangesOnlyWhenRequested() async {
        let cancellation = TestCancellation()

        #expect(await cancellation.isCancelled() == false)
        await cancellation.cancel()
        #expect(await cancellation.isCancelled())
    }

    @Test
    func featureFactoriesCreateDeterministicRegistryInputs() throws {
        let id = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let registry = FeatureRegistry(factories: [FeatureFixtures.factory(id: id)])

        #expect(registry.descriptors == [FeatureFixtures.descriptor(id: id)])
    }
}
