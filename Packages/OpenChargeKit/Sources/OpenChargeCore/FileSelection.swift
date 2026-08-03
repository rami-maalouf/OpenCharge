import Foundation

public enum FileSelectionItemKind: String, Hashable, Codable, Sendable {
    case alias
    case directory
    case file
    case other
    case package
    case symbolicLink
}

public struct FileSelectionItem: Hashable, Codable, Sendable {
    public let inputIndex: Int
    public let url: URL
    public let kind: FileSelectionItemKind

    public init(inputIndex: Int, url: URL, kind: FileSelectionItemKind) {
        self.inputIndex = inputIndex
        self.url = url
        self.kind = kind
    }
}

public enum FileSelectionIssueReason: String, Hashable, Codable, Sendable {
    case missingItem
    case notFileURL
    case relativeFileURL
}

public struct FileSelectionIssue: Hashable, Codable, Sendable {
    public let inputIndex: Int
    public let url: URL
    public let reason: FileSelectionIssueReason

    public init(
        inputIndex: Int,
        url: URL,
        reason: FileSelectionIssueReason
    ) {
        self.inputIndex = inputIndex
        self.url = url
        self.reason = reason
    }
}

public struct FileSelection: Hashable, Codable, Sendable {
    public let items: [FileSelectionItem]
    public let issues: [FileSelectionIssue]

    public init(
        items: [FileSelectionItem],
        issues: [FileSelectionIssue]
    ) {
        self.items = items
        self.issues = issues
    }

    public var urls: [URL] {
        items.map(\.url)
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public var hasIssues: Bool {
        !issues.isEmpty
    }
}
