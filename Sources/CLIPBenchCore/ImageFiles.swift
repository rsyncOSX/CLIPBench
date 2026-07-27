import CoreGraphics
import Foundation
import ImageIO
import PhotoAIContracts

public enum ImageFileDiscovery {
    public static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff",
    ]

    public static func sources(
        in directory: URL,
        recursive: Bool = true
    ) throws -> [AIImageSource] {
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .isHiddenKey,
        ]
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: recursive
                ? [.skipsHiddenFiles, .skipsPackageDescendants]
                : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            throw CLIPBenchError.cannotReadDirectory(directory.path)
        }
        return try enumerator.compactMap { element in
            guard let url = element as? URL,
                  supportedExtensions.contains(
                      url.pathExtension.lowercased()
                  )
            else {
                return nil
            }
            let values = try url.resourceValues(forKeys: Set(keys))
            guard values.isRegularFile == true, values.isHidden != true else {
                return nil
            }
            return AIImageSource(
                id: UUID(),
                url: url.standardizedFileURL,
                displayName: url.lastPathComponent
            )
        }
        .sorted {
            $0.url.path.localizedStandardCompare($1.url.path)
                == .orderedAscending
        }
    }
}

public struct ImageIOImageDecoder: ImageDecoding {
    public let thumbnailMaximumPixelSize: Int

    public init(thumbnailMaximumPixelSize: Int = 2048) {
        self.thumbnailMaximumPixelSize = thumbnailMaximumPixelSize
    }

    public func image(for source: AIImageSource) async throws -> CGImage {
        try Task.checkCancellation()
        guard let imageSource = CGImageSourceCreateWithURL(
            source.url as CFURL,
            nil
        ) else {
            throw CLIPBenchError.cannotDecodeImage(source.url.path)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaximumPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            options as CFDictionary
        ) else {
            throw CLIPBenchError.cannotDecodeImage(source.url.path)
        }
        return image
    }
}
