public struct FeatureID: RawRepresentable, Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init?(rawValue: String) {
        let namespaceSegments = rawValue.split(separator: ".", omittingEmptySubsequences: false)

        guard namespaceSegments.count >= 2,
              namespaceSegments.allSatisfy(Self.isValidSegment)
        else {
            return nil
        }

        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid feature identifier."
            )
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    private static func isValidSegment(_ segment: Substring) -> Bool {
        guard !segment.isEmpty,
              segment.first != "-",
              segment.last != "-",
              !segment.contains("--")
        else {
            return false
        }

        return segment.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 45, 48 ... 57, 97 ... 122:
                true
            default:
                false
            }
        }
    }
}
