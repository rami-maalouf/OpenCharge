import AppKit
import Foundation
import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@MainActor
@Suite("Pasteboard client")
struct PasteboardClientTests {
    @Test
    func successfulWriteClearsStaleTypesAndWritesOnlyExplicitValues() throws {
        let pasteboard = makeIsolatedPasteboard()
        defer { pasteboard.releaseGlobally() }
        let staleType = NSPasteboard.PasteboardType("test.opencharge.stale")
        pasteboard.clearContents()
        #expect(pasteboard.setString("stale", forType: staleType))
        let custom = try #require(
            PasteboardValue(
                typeIdentifier: "test.opencharge.custom",
                data: Data([0x01, 0x02])
            )
        )
        let client = PasteboardClient(pasteboard: pasteboard)

        try client.write([.plainText("private text"), custom])

        #expect(pasteboard.data(forType: staleType) == nil)
        #expect(
            pasteboard.string(forType: .string) == "private text"
        )
        #expect(
            pasteboard.data(
                forType: NSPasteboard.PasteboardType(custom.typeIdentifier)
            ) == custom.data
        )
        #expect(
            Set(pasteboard.types ?? [])
                == [
                    .string,
                    NSPasteboard.PasteboardType("NSStringPboardType"),
                    NSPasteboard.PasteboardType(custom.typeIdentifier)
                ]
        )
    }

    @Test
    func backendReceivesOnlyExplicitValuesAndRetainsNoHistory() throws {
        let backend = PasteboardBackendProbe(
            storedValues: ["test.opencharge.stale": Data([0x01])]
        )
        let client = PasteboardClient(backend: backend)
        let custom = try #require(
            PasteboardValue(
                typeIdentifier: "test.opencharge.custom",
                data: Data([0x02])
            )
        )

        try client.write([.plainText("current"), custom])

        #expect(backend.clearCount == 1)
        #expect(
            backend.storedValues
                == [
                    PasteboardValue.plainTextTypeIdentifier: Data("current".utf8),
                    custom.typeIdentifier: custom.data
                ]
        )
    }

    @Test
    func emptyAndDuplicateValuesFailBeforeClearingContents() throws {
        let backend = PasteboardBackendProbe(
            storedValues: ["test.opencharge.stale": Data([0x01])]
        )
        let client = PasteboardClient(backend: backend)
        let duplicate = PasteboardValue.plainText("second")

        #expect(throws: PasteboardClientError.emptyValues) {
            try client.write([])
        }
        #expect(
            throws: PasteboardClientError.duplicateTypeIdentifier(
                PasteboardValue.plainTextTypeIdentifier
            )
        ) {
            try client.write([.plainText("first"), duplicate])
        }
        #expect(backend.clearCount == 0)
        #expect(backend.storedValues == ["test.opencharge.stale": Data([0x01])])
    }

    @Test
    func backendFailureExposesOnlyTheFailedType() throws {
        let failedType = "test.opencharge.failed"
        let backend = PasteboardBackendProbe(failedTypeIdentifier: failedType)
        let client = PasteboardClient(backend: backend)
        let privateData = Data("private clipboard contents".utf8)
        let value = try #require(
            PasteboardValue(
                typeIdentifier: failedType,
                data: privateData
            )
        )

        #expect(
            throws: PasteboardClientError.writeFailed(
                typeIdentifier: failedType
            )
        ) {
            try client.write([value])
        }
        #expect(backend.clearCount == 1)
        #expect(!String(describing: backend.lastError).contains("private"))
    }

    @Test
    func valueRejectsInvalidTypeIdentifiersButAllowsExplicitEmptyData() {
        #expect(PasteboardValue(typeIdentifier: "", data: Data()) == nil)
        #expect(
            PasteboardValue(
                typeIdentifier: "public.utf8 plain-text",
                data: Data()
            ) == nil
        )
        let emptyText = PasteboardValue.plainText("")
        #expect(emptyText.typeIdentifier == PasteboardValue.plainTextTypeIdentifier)
        #expect(emptyText.data.isEmpty)
    }

    private func makeIsolatedPasteboard() -> NSPasteboard {
        NSPasteboard(
            name: NSPasteboard.Name(
                "studio.orbitlabs.opencharge.tests.\(UUID())"
            )
        )
    }
}

@MainActor
private final class PasteboardBackendProbe: PasteboardAccessing {
    private let failedTypeIdentifier: String?
    private(set) var clearCount = 0
    private(set) var lastError: PasteboardClientError?
    private(set) var storedValues: [String: Data]

    init(
        storedValues: [String: Data] = [:],
        failedTypeIdentifier: String? = nil
    ) {
        self.storedValues = storedValues
        self.failedTypeIdentifier = failedTypeIdentifier
    }

    func clearContents() {
        clearCount += 1
        storedValues.removeAll()
    }

    func setData(_ data: Data, forTypeIdentifier: String) -> Bool {
        guard forTypeIdentifier != failedTypeIdentifier else {
            lastError = .writeFailed(typeIdentifier: forTypeIdentifier)
            return false
        }
        storedValues[forTypeIdentifier] = data
        return true
    }
}
