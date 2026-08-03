import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Permission state")
struct PermissionStateTests {
    @Test
    func exposesFoundationAndFinderPermissionKinds() {
        #expect(
            Set(PermissionKind.allCases) == [
                .accessibility,
                .automation,
                .finderSync,
                .screenRecording
            ]
        )
    }

    @Test
    func distinguishesEveryPermissionState() {
        let states: Set<PermissionState> = [
            .notDetermined,
            .denied,
            .restricted,
            .granted,
            .unavailable(reasonKey: "permission.unavailable")
        ]

        #expect(states.count == 5)
        #expect(PermissionState.granted.isGranted)
        #expect(PermissionState.denied.isGranted == false)
    }

    @Test
    func stateRoundTripsThroughJSON() throws {
        let state = PermissionState.unavailable(reasonKey: "permission.finderSync.unavailable")

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PermissionState.self, from: encoded)

        #expect(decoded == state)
    }
}
