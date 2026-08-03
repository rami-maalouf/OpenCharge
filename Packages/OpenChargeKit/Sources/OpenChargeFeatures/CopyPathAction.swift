import Foundation
import OpenChargeCore

public struct CopyPathOutput: Hashable, Codable, Sendable {
    public let paths: [String]

    public init(paths: [String]) {
        self.paths = paths
    }

    public var text: String {
        paths.joined(separator: "\n")
    }
}

public struct CopyPathAction: Sendable {
    public typealias TextWriter = @Sendable (String) async throws -> Void

    private let normalizer: FileSelectionNormalizer
    private let writeText: TextWriter

    public init(
        normalizer: FileSelectionNormalizer = FileSelectionNormalizer(),
        writeText: @escaping TextWriter
    ) {
        self.normalizer = normalizer
        self.writeText = writeText
    }

    public func copy(_ urls: [URL]) async -> ActionResult<CopyPathOutput> {
        let selection = normalizer.normalize(urls)
        guard !selection.isEmpty else {
            let reasonKey = selection.hasIssues
                ? "feature.copyPath.noValidSelection"
                : "feature.copyPath.emptySelection"
            return .failure(.invalidInput(reasonKey: reasonKey))
        }

        let output = CopyPathOutput(paths: selection.urls.map(\.path))
        do {
            try await writeText(output.text)
        } catch {
            return .failure(
                .systemFailure(reasonKey: "feature.copyPath.writeFailed")
            )
        }

        let failures = selection.issues.map(actionError(for:))
        guard !failures.isEmpty else {
            return .success(output)
        }
        return .partialSuccess(successes: [output], failures: failures)
    }

    private func actionError(for issue: FileSelectionIssue) -> ActionError {
        let reasonKey = switch issue.reason {
        case .missingItem:
            "feature.copyPath.missingItem"
        case .notFileURL:
            "feature.copyPath.notFileURL"
        case .relativeFileURL:
            "feature.copyPath.relativeFileURL"
        }
        return .invalidInput(reasonKey: reasonKey)
    }
}
