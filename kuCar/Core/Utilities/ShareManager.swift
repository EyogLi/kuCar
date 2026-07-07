import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Manages sharing/export of edited car images.
@MainActor
final class ShareManager: ObservableObject {

    // MARK: - Export

    func exportImage(_ image: CGImage, configuration: ExportConfiguration) async throws -> URL {
        let uiImage = UIImage(cgImage: image)

        // Resize if needed
        let resizedImage: UIImage
        if let maxDim = configuration.resolution.maxDimension {
            resizedImage = resizeImage(uiImage, maxDimension: CGFloat(maxDim))
        } else {
            resizedImage = uiImage
        }

        // Add watermark if configured
        let finalImage: UIImage
        if configuration.includeWatermark {
            finalImage = addWatermark(to: resizedImage)
        } else {
            finalImage = resizedImage
        }

        // Encode data
        let data: Data?
        switch configuration.format {
        case .jpeg:
            data = finalImage.jpegData(compressionQuality: 0.95)
        case .png:
            data = finalImage.pngData()
        case .heic:
            data = finalImage.heicData()
        }

        guard let imageData = data else {
            throw ShareError.exportFailed
        }

        // Write to temporary file
        let fileName = "kuCar_\(Date().timeIntervalSince1970).\(configuration.format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try imageData.write(to: tempURL)

        return tempURL
    }

    // MARK: - Share Sheet

    func shareSheet(for url: URL) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        controller.excludedActivityTypes = [.assignToContact, .addToReadingList]
        return controller
    }

    // MARK: - Private Helpers

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxEdge = max(size.width, size.height)

        guard maxEdge > maxDimension else { return image }

        let scale = maxDimension / maxEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(at: .zero)

            let watermarkText = "kuCar AI"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: max(image.size.width * 0.03, 14)),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .strokeColor: UIColor.black.withAlphaComponent(0.3),
                .strokeWidth: -1
            ]

            let textSize = watermarkText.size(withAttributes: attributes)
            let padding: CGFloat = 16
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - HEIC Encoding

extension UIImage {
    func heicData(compressionQuality: CGFloat = 0.9) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data, "public.heic" as CFString, 1, nil
        ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data
    }
}

enum ShareError: LocalizedError {
    case exportFailed

    var errorDescription: String? {
        "导出图片失败"
    }
}
