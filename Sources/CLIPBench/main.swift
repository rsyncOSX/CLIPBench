import CLIPBenchCore
import CoreAICLIPBackend
import Foundation

@main
struct CLIPBenchCommand {
    static func main() async {
        do {
            try await run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data("error: \(error)\n".utf8)
            )
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func run(_ arguments: [String]) async throws {
        guard let command = arguments.first else {
            print(usage)
            return
        }
        let parsed = ParsedArguments(Array(arguments.dropFirst()))
        switch command {
        case "inspect-model":
            try inspectModel(parsed)
        case "index":
            try await index(parsed)
        case "search":
            try await search(parsed)
        case "compare":
            try await compare(parsed)
        case "benchmark":
            try await benchmark(parsed)
        case "parity":
            try await parity(parsed)
        case "help", "--help", "-h":
            print(usage)
        default:
            throw CLIPBenchError.invalidArguments(
                "Unknown command '\(command)'.\n\n\(usage)"
            )
        }
    }

    private static func inspectModel(_ arguments: ParsedArguments) throws {
        let modelURL = try arguments.requiredURL(for: "--model")
        let provider = try CoreAICLIPProvider(modelBundleURL: modelURL)
        let configuration = provider.runtimeConfiguration
        print("model fingerprint\t\(provider.modelIdentity.artifactIdentifier)")
        print("source\t\(configuration.sourceModel ?? "unknown")")
        print("architecture\t\(configuration.architecture)")
        print("pretrained\t\(configuration.pretrained ?? "none")")
        print(
            "image input\t\(configuration.preprocessing.width)x"
                + "\(configuration.preprocessing.height), "
                + "\(configuration.preprocessing.resize), "
                + "\(configuration.preprocessing.crop), "
                + configuration.preprocessing.interpolation
        )
        print("image function\t\(configuration.imageFunctionName)")
        print("text function\t\(configuration.textFunctionName)")
        print("tokenizer\t\(configuration.tokenizer.version)")
        print(
            "embedding dimensions\t"
                + "\(configuration.embeddingDimensions.map(String.init) ?? "model-defined")"
        )
    }

    private static func index(_ arguments: ParsedArguments) async throws {
        let directory = try arguments.requiredPositionalURL(at: 0)
        let engine = try makeEngine(arguments, directory: directory)
        let summary = try await engine.synchronize(directory: directory) {
            progress in
            let name = progress.currentFileName.map { " \($0)" } ?? ""
            print("[\(progress.completed)/\(progress.total)]\(name)")
        }
        print(
            "discovered=\(summary.discovered) reused=\(summary.reused) "
                + "indexed=\(summary.indexed) failed=\(summary.failures.count)"
        )
        for failure in summary.failures {
            print("failed\t\(failure)")
        }
    }

    private static func search(_ arguments: ParsedArguments) async throws {
        let directory = try arguments.requiredPositionalURL(at: 0)
        let query = try arguments.requiredPositional(at: 1)
        let limit = try arguments.integer(for: "--top", default: 10)
        let engine = try makeEngine(arguments, directory: directory)
        let results = try await engine.search(text: query, limit: limit)
        if arguments.hasFlag("--json") {
            print(try jsonString(results))
        } else {
            printResults(results, heading: nil)
        }
    }

    private static func compare(_ arguments: ParsedArguments) async throws {
        let directory = try arguments.requiredPositionalURL(at: 0)
        let query = try arguments.requiredPositional(at: 1)
        let modelURLs = arguments.urls(for: "--model")
        guard modelURLs.count >= 2 else {
            throw CLIPBenchError.invalidArguments(
                "compare requires at least two --model paths."
            )
        }
        let limit = try arguments.integer(for: "--top", default: 10)
        for modelURL in modelURLs {
            let provider = try CoreAICLIPProvider(modelBundleURL: modelURL)
            let indexURL = CLIPBenchPaths.defaultIndexURL(
                directory: directory,
                modelFingerprint: provider.backendDescriptor.modelFingerprint
            )
            let engine = CLIPSearchEngine(
                provider: provider,
                indexStore: CLIPIndexStore(fileURL: indexURL),
                concurrencyLimit: try arguments.integer(
                    for: "--jobs",
                    default: 2
                )
            )
            let summary = try await engine.synchronize(directory: directory)
            let results = try await engine.search(text: query, limit: limit)
            let label = provider.runtimeConfiguration.pretrained
                ?? provider.runtimeConfiguration.architecture
            print(
                "\n=== \(label) — \(summary.discovered) images, "
                    + "\(summary.indexed) newly indexed ==="
            )
            printResults(results, heading: nil)
        }
    }

    private static func benchmark(
        _ arguments: ParsedArguments
    ) async throws {
        let directory = try arguments.requiredPositionalURL(at: 0)
        let manifestURL = try arguments.requiredURL(for: "--manifest")
        let engine = try makeEngine(arguments, directory: directory)
        _ = try await engine.synchronize(directory: directory)
        let manifest = try JSONDecoder().decode(
            CLIPBenchmarkManifest.self,
            from: Data(contentsOf: manifestURL)
        )
        let report = try await CLIPBenchmarkRunner.run(
            manifest: manifest,
            engine: engine
        )
        if let outputURL = arguments.optionalURL(for: "--output") {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(report).write(
                to: outputURL,
                options: .atomic
            )
            print("wrote\t\(outputURL.path)")
        }
        print("collection\t\(report.collection)")
        print("model\t\(report.modelFingerprint)")
        print(
            "mean P@5=\(formatted(report.meanMetrics.precisionAt5)) "
                + "P@10=\(formatted(report.meanMetrics.precisionAt10)) "
                + "R@5=\(formatted(report.meanMetrics.recallAt5)) "
                + "R@10=\(formatted(report.meanMetrics.recallAt10)) "
                + "MRR=\(formatted(report.meanMetrics.reciprocalRank))"
        )
    }

    private static func parity(_ arguments: ParsedArguments) async throws {
        let modelURL = try arguments.requiredURL(for: "--model")
        let referenceURL = try arguments.requiredURL(for: "--reference")
        let threshold = try arguments.floatingPoint(
            for: "--minimum-cosine",
            default: 0.99
        )
        let provider = try CoreAICLIPProvider(modelBundleURL: modelURL)
        let decoder = JSONDecoder()
        let reference = try decoder.decode(
            CLIPParityReference.self,
            from: Data(contentsOf: referenceURL)
        )
        let report = try await CLIPParityRunner.run(
            reference: reference,
            referenceDirectory: referenceURL.deletingLastPathComponent(),
            provider: provider
        )
        print("kind\tcosine\tmax-absolute-error\tlabel")
        for sample in report.samples {
            print(
                "\(sample.kind)\t"
                    + "\(formatted(Double(sample.cosineSimilarity)))\t"
                    + "\(formatted(Double(sample.maximumAbsoluteError)))\t"
                    + sample.label
            )
        }
        print(
            "minimum cosine\t"
                + formatted(Double(report.minimumCosineSimilarity))
        )
        guard report.minimumCosineSimilarity >= Float(threshold) else {
            throw CLIPBenchError.invalidArguments(
                "Core AI parity is below \(threshold)."
            )
        }
    }

    private static func makeEngine(
        _ arguments: ParsedArguments,
        directory: URL
    ) throws -> CLIPSearchEngine {
        let modelURL = try arguments.requiredURL(for: "--model")
        let provider = try CoreAICLIPProvider(modelBundleURL: modelURL)
        let indexURL = arguments.optionalURL(for: "--index")
            ?? CLIPBenchPaths.defaultIndexURL(
                directory: directory,
                modelFingerprint: provider.backendDescriptor.modelFingerprint
            )
        return CLIPSearchEngine(
            provider: provider,
            indexStore: CLIPIndexStore(fileURL: indexURL),
            concurrencyLimit: try arguments.integer(
                for: "--jobs",
                default: 2
            )
        )
    }

    private static func printResults(
        _ results: [CLIPSearchResult],
        heading: String?
    ) {
        if let heading { print(heading) }
        print("rank\tscore\tfile\tpath")
        for result in results {
            print(
                "\(result.rank)\t\(formatted(Double(result.score)))\t"
                    + "\(result.fileName)\t\(result.path)"
            )
        }
    }

    private static func jsonString<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(
            decoding: try encoder.encode(value),
            as: UTF8.self
        )
    }

    private static func formatted(_ value: Double) -> String {
        String(
            format: "%.4f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }

    private static let usage = """
    clipbench — local Core AI CLIP retrieval experiment

    USAGE
      clipbench inspect-model --model MODEL_BUNDLE
      clipbench index IMAGE_DIR --model MODEL_BUNDLE [--jobs 2]
      clipbench search IMAGE_DIR "QUERY" --model MODEL_BUNDLE [--top 10] [--json]
      clipbench compare IMAGE_DIR "QUERY" --model MODEL_A --model MODEL_B [--top 10]
      clipbench benchmark IMAGE_DIR --manifest MANIFEST --model MODEL_BUNDLE [--output REPORT]
      clipbench parity --reference SOURCE_JSON --model MODEL_BUNDLE [--minimum-cosine 0.99]

    IMAGE INPUT
      JPEG, PNG, HEIC/HEIF, and TIFF files are supported. Extracted RAW
      thumbnails can be indexed once written in one of these formats.
    """
}

private struct ParsedArguments {
    let positionals: [String]
    private let values: [String: [String]]
    private let flags: Set<String>

    init(_ arguments: [String]) {
        var positionals = [String]()
        var values = [String: [String]]()
        var flags = Set<String>()
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument.hasPrefix("--") {
                if index + 1 < arguments.count,
                   !arguments[index + 1].hasPrefix("--") {
                    values[argument, default: []].append(
                        arguments[index + 1]
                    )
                    index += 2
                } else {
                    flags.insert(argument)
                    index += 1
                }
            } else {
                positionals.append(argument)
                index += 1
            }
        }
        self.positionals = positionals
        self.values = values
        self.flags = flags
    }

    func requiredPositional(at index: Int) throws -> String {
        guard positionals.indices.contains(index) else {
            throw CLIPBenchError.invalidArguments(
                "Missing positional argument \(index + 1)."
            )
        }
        return positionals[index]
    }

    func requiredPositionalURL(at index: Int) throws -> URL {
        URL(fileURLWithPath: try requiredPositional(at: index))
            .standardizedFileURL
    }

    func requiredURL(for option: String) throws -> URL {
        guard let url = optionalURL(for: option) else {
            throw CLIPBenchError.invalidArguments(
                "Missing required option \(option)."
            )
        }
        return url
    }

    func optionalURL(for option: String) -> URL? {
        values[option]?.last.map {
            URL(fileURLWithPath: $0).standardizedFileURL
        }
    }

    func urls(for option: String) -> [URL] {
        (values[option] ?? []).map {
            URL(fileURLWithPath: $0).standardizedFileURL
        }
    }

    func integer(for option: String, default defaultValue: Int) throws -> Int {
        guard let rawValue = values[option]?.last else {
            return defaultValue
        }
        guard let value = Int(rawValue), value > 0 else {
            throw CLIPBenchError.invalidArguments(
                "\(option) must be a positive integer."
            )
        }
        return value
    }

    func floatingPoint(
        for option: String,
        default defaultValue: Double
    ) throws -> Double {
        guard let rawValue = values[option]?.last else {
            return defaultValue
        }
        guard let value = Double(rawValue), value.isFinite else {
            throw CLIPBenchError.invalidArguments(
                "\(option) must be a finite number."
            )
        }
        return value
    }

    func hasFlag(_ option: String) -> Bool {
        flags.contains(option)
    }
}
