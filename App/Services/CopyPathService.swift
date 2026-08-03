import AppKit
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem

@MainActor
final class CopyPathService {
    private static let legacyFilenamesType = NSPasteboard.PasteboardType(
        "NSFilenamesPboardType"
    )

    private let action: CopyPathAction

    init(pasteboard: any PasteboardWriting = PasteboardClient()) {
        action = CopyPathAction { text in
            try await pasteboard.writePlainText(text)
        }
    }

    func copy(from pasteboard: NSPasteboard) async -> ActionResult<CopyPathOutput> {
        await copy(fileURLs(from: pasteboard))
    }

    func copy(_ fileURLs: [URL]) async -> ActionResult<CopyPathOutput> {
        await action.copy(fileURLs)
    }

    func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        let modernURLs = (pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) as? [NSURL] ?? []).map { $0 as URL }
        if !modernURLs.isEmpty {
            return modernURLs
        }

        let legacyPaths = pasteboard.propertyList(
            forType: Self.legacyFilenamesType
        ) as? [String] ?? []
        return legacyPaths.map {
            URL(filePath: $0, directoryHint: .checkFileSystem)
        }
    }
}
