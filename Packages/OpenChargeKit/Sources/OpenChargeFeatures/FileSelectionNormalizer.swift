import Foundation
import OpenChargeCore

public struct FileSelectionNormalizer: Sendable {
    public init() {}

    public func normalize(_ urls: [URL]) -> FileSelection {
        var items: [FileSelectionItem] = []
        var issues: [FileSelectionIssue] = []

        for (inputIndex, inputURL) in urls.enumerated() {
            guard inputURL.isFileURL else {
                issues.append(
                    FileSelectionIssue(
                        inputIndex: inputIndex,
                        url: inputURL,
                        reason: .notFileURL
                    )
                )
                continue
            }
            guard inputURL.path.hasPrefix("/") else {
                issues.append(
                    FileSelectionIssue(
                        inputIndex: inputIndex,
                        url: inputURL,
                        reason: .relativeFileURL
                    )
                )
                continue
            }

            let normalizedURL = inputURL.standardizedFileURL
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(
                atPath: normalizedURL.path,
                isDirectory: &isDirectory
            ) else {
                issues.append(
                    FileSelectionIssue(
                        inputIndex: inputIndex,
                        url: normalizedURL,
                        reason: .missingItem
                    )
                )
                continue
            }

            items.append(
                FileSelectionItem(
                    inputIndex: inputIndex,
                    url: normalizedURL,
                    kind: kind(for: normalizedURL, isDirectory: isDirectory.boolValue)
                )
            )
        }

        return FileSelection(items: items, issues: issues)
    }

    private func kind(
        for url: URL,
        isDirectory: Bool
    ) -> FileSelectionItemKind {
        let keys: Set<URLResourceKey> = [
            .isAliasFileKey,
            .isPackageKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return isDirectory ? .directory : .other
        }
        if values.isSymbolicLink == true {
            return .symbolicLink
        }
        if values.isAliasFile == true {
            return .alias
        }
        if values.isPackage == true {
            return .package
        }
        if isDirectory {
            return .directory
        }
        if values.isRegularFile == true {
            return .file
        }
        return .other
    }
}
