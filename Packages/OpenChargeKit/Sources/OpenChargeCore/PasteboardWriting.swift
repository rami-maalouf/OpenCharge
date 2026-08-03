import Foundation

public struct PasteboardValue: Hashable, Codable, Sendable {
    public static let plainTextTypeIdentifier = "public.utf8-plain-text"

    public let typeIdentifier: String
    public let data: Data

    public init?(typeIdentifier: String, data: Data) {
        guard Self.isValid(typeIdentifier: typeIdentifier) else {
            return nil
        }
        self.typeIdentifier = typeIdentifier
        self.data = data
    }

    public static func plainText(_ text: String) -> Self {
        Self(
            validatedTypeIdentifier: plainTextTypeIdentifier,
            data: Data(text.utf8)
        )
    }

    private init(validatedTypeIdentifier: String, data: Data) {
        typeIdentifier = validatedTypeIdentifier
        self.data = data
    }

    private static func isValid(typeIdentifier: String) -> Bool {
        guard !typeIdentifier.isEmpty else {
            return false
        }
        return typeIdentifier.unicodeScalars.allSatisfy {
            !CharacterSet.whitespacesAndNewlines.contains($0)
        }
    }
}

@MainActor
public protocol PasteboardWriting: AnyObject, Sendable {
    func write(_ values: [PasteboardValue]) throws
}

public extension PasteboardWriting {
    func writePlainText(_ text: String) throws {
        try write([.plainText(text)])
    }
}
