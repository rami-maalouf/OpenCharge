import Foundation
import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("Power assertion controller")
struct PowerAssertionControllerTests {
    @Test
    func createsOnlyAssertionsRequiredByEachTransition() async throws {
        let probe = PowerAssertionProbe(createIDs: [.success(11), .success(22)])
        let controller = makeController(probe: probe)

        let idle = try await controller.apply(.idleSystem)
        let display = try await controller.apply(.idleSystemAndDisplay)

        #expect(idle == .idleSystem)
        #expect(display == .idleSystemAndDisplay)
        #expect(probe.createdKinds == [.idleSystem, .display])
        #expect(probe.releasedIDs.isEmpty)
    }

    @Test
    func releasesOnlyAssertionsNoLongerRequired() async throws {
        let probe = PowerAssertionProbe(createIDs: [.success(11), .success(22)])
        let controller = makeController(probe: probe)
        try await controller.apply(.idleSystemAndDisplay)

        let idle = try await controller.apply(.idleSystem)
        let disabled = try await controller.apply(.disabled)

        #expect(idle == .idleSystem)
        #expect(disabled == .disabled)
        #expect(probe.releasedIDs == [22, 11])
        #expect(probe.releaseCallCount(for: 22) == 1)
        #expect(probe.releaseCallCount(for: 11) == 1)
    }

    @Test
    func partialCreationFailureRollsBackNewAssertions() async {
        let probe = PowerAssertionProbe(
            createIDs: [.success(11), .failure(.expected)]
        )
        let controller = makeController(probe: probe)

        await #expect(throws: PowerAssertionProbeError.self) {
            try await controller.apply(.idleSystemAndDisplay)
        }

        #expect(probe.createdKinds == [.idleSystem, .display])
        #expect(probe.releasedIDs == [11])
        #expect(await controller.currentConfiguration() == .disabled)
    }

    @Test
    func creationFailurePreservesPreexistingAssertions() async throws {
        let probe = PowerAssertionProbe(
            createIDs: [.success(11), .failure(.expected)]
        )
        let controller = makeController(probe: probe)
        try await controller.apply(.idleSystem)

        await #expect(throws: PowerAssertionProbeError.self) {
            try await controller.apply(.idleSystemAndDisplay)
        }

        #expect(probe.releasedIDs.isEmpty)
        #expect(await controller.currentConfiguration() == .idleSystem)
    }

    @Test
    func repeatedConfigurationDoesNotTouchIOKit() async throws {
        let probe = PowerAssertionProbe(createIDs: [.success(11)])
        let controller = makeController(probe: probe)

        try await controller.apply(.idleSystem)
        try await controller.apply(.idleSystem)

        #expect(probe.createdKinds == [.idleSystem])
        #expect(probe.releasedIDs.isEmpty)
    }

    @Test
    func failedReleaseRetainsOwnershipForRetry() async throws {
        let probe = PowerAssertionProbe(
            createIDs: [.success(11)],
            releaseResults: [.failure(.expected), .success(())]
        )
        let controller = makeController(probe: probe)
        try await controller.apply(.idleSystem)

        await #expect(throws: PowerAssertionProbeError.self) {
            try await controller.apply(.disabled)
        }
        #expect(await controller.currentConfiguration() == .idleSystem)

        try await controller.apply(.disabled)

        #expect(await controller.currentConfiguration() == .disabled)
        #expect(probe.releaseCallCount(for: 11) == 2)
    }

    @Test
    func deinitializationReleasesEveryOwnedAssertionOnce() async throws {
        let probe = PowerAssertionProbe(createIDs: [.success(11), .success(22)])

        try await createAndDropController(probe: probe)

        #expect(probe.releasedIDs == [11, 22] || probe.releasedIDs == [22, 11])
        #expect(probe.releaseCallCount(for: 11) == 1)
        #expect(probe.releaseCallCount(for: 22) == 1)
    }

    private func makeController(
        probe: PowerAssertionProbe
    ) -> PowerAssertionController {
        PowerAssertionController(
            createAssertion: probe.create,
            releaseAssertion: probe.release
        )
    }

    private func createAndDropController(
        probe: PowerAssertionProbe
    ) async throws {
        let controller = makeController(probe: probe)
        try await controller.apply(.idleSystemAndDisplay)
    }
}

private enum PowerAssertionProbeError: Error {
    case expected
    case exhausted
}

private final class PowerAssertionProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var createIDs: [Result<UInt32, PowerAssertionProbeError>]
    private var releaseResults: [Result<Void, PowerAssertionProbeError>]
    private var storedCreatedKinds: [PowerAssertionKind] = []
    private var storedReleasedIDs: [UInt32] = []

    init(
        createIDs: [Result<UInt32, PowerAssertionProbeError>],
        releaseResults: [Result<Void, PowerAssertionProbeError>] = []
    ) {
        self.createIDs = createIDs
        self.releaseResults = releaseResults
    }

    var createdKinds: [PowerAssertionKind] {
        lock.withLock { storedCreatedKinds }
    }

    var releasedIDs: [UInt32] {
        lock.withLock { storedReleasedIDs }
    }

    func releaseCallCount(for id: UInt32) -> Int {
        lock.withLock {
            storedReleasedIDs.count { $0 == id }
        }
    }

    func create(kind: PowerAssertionKind) throws -> UInt32 {
        try lock.withLock {
            storedCreatedKinds.append(kind)
            guard !createIDs.isEmpty else {
                throw PowerAssertionProbeError.exhausted
            }
            return try createIDs.removeFirst().get()
        }
    }

    func release(id: UInt32) throws {
        try lock.withLock {
            storedReleasedIDs.append(id)
            guard !releaseResults.isEmpty else {
                return
            }
            try releaseResults.removeFirst().get()
        }
    }
}
