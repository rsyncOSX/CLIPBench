import CoreAICLIPBackend
import Foundation
import PhotoAIContracts

public struct CLIPParityReference: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let source: CLIPParitySource
    public let images: [CLIPParityImage]
    public let texts: [CLIPParityText]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case source
        case images
        case texts
    }
}

public struct CLIPParitySource: Codable, Equatable, Sendable {
    public let model: String
    public let architecture: String
    public let pretrained: String?
}

public struct CLIPParityImage: Codable, Equatable, Sendable {
    public let path: String
    public let embedding: [Float]
}

public struct CLIPParityText: Codable, Equatable, Sendable {
    public let text: String
    public let embedding: [Float]
}

public struct CLIPParitySampleResult: Codable, Equatable, Sendable {
    public let kind: String
    public let label: String
    public let cosineSimilarity: Float
    public let maximumAbsoluteError: Float

    public var passed: Bool {
        cosineSimilarity.isFinite
    }
}

public struct CLIPParityReport: Codable, Equatable, Sendable {
    public let modelFingerprint: String
    public let samples: [CLIPParitySampleResult]

    public var minimumCosineSimilarity: Float {
        samples.map(\.cosineSimilarity).min() ?? 0
    }
}

public enum CLIPParityRunner {
    public static func run(
        reference: CLIPParityReference,
        referenceDirectory: URL,
        provider: CoreAICLIPProvider,
        decoder: ImageIOImageDecoder = ImageIOImageDecoder()
    ) async throws -> CLIPParityReport {
        guard reference.schemaVersion == 1 else {
            throw CLIPBenchError.invalidArguments(
                "Unsupported parity-reference schema."
            )
        }
        var samples = [CLIPParitySampleResult]()
        for imageReference in reference.images {
            let candidateURL = URL(fileURLWithPath: imageReference.path)
            let url = imageReference.path.hasPrefix("/")
                ? candidateURL
                : referenceDirectory.appendingPathComponent(
                    imageReference.path
                )
            let source = AIImageSource(
                id: UUID(),
                url: url,
                displayName: url.lastPathComponent
            )
            let image = try await decoder.image(for: source)
            let embedding = try await provider.embedding(for: image)
            samples.append(try compare(
                kind: "image",
                label: imageReference.path,
                reference: imageReference.embedding,
                actual: embedding.values
            ))
        }
        for textReference in reference.texts {
            let embedding = try await provider.embedding(
                for: textReference.text
            )
            samples.append(try compare(
                kind: "text",
                label: textReference.text,
                reference: textReference.embedding,
                actual: embedding.values
            ))
        }
        return CLIPParityReport(
            modelFingerprint: provider.backendDescriptor.modelFingerprint,
            samples: samples
        )
    }

    private static func compare(
        kind: String,
        label: String,
        reference: [Float],
        actual: [Float]
    ) throws -> CLIPParitySampleResult {
        guard !reference.isEmpty, reference.count == actual.count else {
            throw CLIPBenchError.invalidArguments(
                "\(kind) parity dimensions do not match for \(label)."
            )
        }
        let dot = zip(reference, actual).reduce(Float.zero) {
            $0 + ($1.0 * $1.1)
        }
        let referenceNorm = sqrt(
            reference.reduce(Float.zero) { $0 + ($1 * $1) }
        )
        let actualNorm = sqrt(
            actual.reduce(Float.zero) { $0 + ($1 * $1) }
        )
        let cosine = dot / (referenceNorm * actualNorm)
        let maximumError = zip(reference, actual).reduce(Float.zero) {
            max($0, abs($1.0 - $1.1))
        }
        return CLIPParitySampleResult(
            kind: kind,
            label: label,
            cosineSimilarity: cosine,
            maximumAbsoluteError: maximumError
        )
    }
}
