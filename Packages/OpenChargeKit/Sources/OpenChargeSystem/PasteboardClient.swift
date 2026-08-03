import AppKit
import OpenChargeCore

public enum PasteboardClientError: Error, Hashable, Sendable {
    case duplicateTypeIdentifier(String)
    case emptyValues
    case writeFailed(typeIdentifier: String)
}

@MainActor
public final class PasteboardClient: PasteboardWriting {
    private let backend: any PasteboardAccessing

    public convenience init(pasteboard: NSPasteboard = .general) {
        self.init(backend: AppKitPasteboardBackend(pasteboard: pasteboard))
    }

    init(backend: any PasteboardAccessing) {
        self.backend = backend
    }

    public func write(_ values: [PasteboardValue]) throws {
        guard !values.isEmpty else {
            throw PasteboardClientError.emptyValues
        }

        var typeIdentifiers: Set<String> = []
        for value in values {
            guard typeIdentifiers.insert(value.typeIdentifier).inserted else {
                throw PasteboardClientError.duplicateTypeIdentifier(
                    value.typeIdentifier
                )
            }
        }

        backend.clearContents()
        for value in values {
            guard backend.setData(
                value.data,
                forTypeIdentifier: value.typeIdentifier
            ) else {
                throw PasteboardClientError.writeFailed(
                    typeIdentifier: value.typeIdentifier
                )
            }
        }
    }
}

@MainActor
protocol PasteboardAccessing: AnyObject {
    func clearContents()
    func setData(_ data: Data, forTypeIdentifier: String) -> Bool
}

@MainActor
private final class AppKitPasteboardBackend: PasteboardAccessing {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard) {
        self.pasteboard = pasteboard
    }

    func clearContents() {
        pasteboard.clearContents()
    }

    func setData(_ data: Data, forTypeIdentifier: String) -> Bool {
        pasteboard.setData(
            data,
            forType: NSPasteboard.PasteboardType(forTypeIdentifier)
        )
    }
}
