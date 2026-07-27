import CryptoKit
import Foundation

public enum CLIPBenchError: Error, CustomStringConvertible, Sendable {
    case cannotReadDirectory(String)
    case cannotDecodeImage(String)
    case emptyQuery
    case missingCompatibleIndex
    case invalidArguments(String)

    public var description: String {
        switch self {
        case let .cannotReadDirectory(path):
            "Cannot read image directory: \(path)"
        case let .cannotDecodeImage(path):
            "Cannot decode image: \(path)"
        case .emptyQuery:
            "The search query is empty."
        case .missingCompatibleIndex:
            "No index compatible with this model was found. Run index first."
        case let .invalidArguments(message):
            message
        }
    }
}

public enum CLIPBenchPaths {
    public static func defaultIndexURL(
        directory: URL,
        modelFingerprint: String
    ) -> URL {
        let digest = SHA256.hash(
            data: Data(modelFingerprint.utf8)
        )
        let hash = digest.prefix(16).map {
            String(format: "%02x", $0)
        }.joined()
        return directory
            .appendingPathComponent(".clipbench", isDirectory: true)
            .appendingPathComponent("clip-\(hash).clipindex")
    }
}
