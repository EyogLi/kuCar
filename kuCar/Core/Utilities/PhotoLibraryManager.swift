import UIKit
import PhotosUI
import SwiftUI

/// Wrapper around PHPicker for clean photo library integration.
@MainActor
final class PhotoLibraryManager: ObservableObject {

    @Published var selectedImageData: Data?
    @Published var selectedImage: UIImage?
    @Published var error: String?

    /// Create a PHPickerViewController configuration.
    func makePickerConfiguration() -> PHPickerConfiguration {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        return config
    }

    /// Process the picker result and extract image data.
    func processPickerResult(_ result: PHPickerResult) async {
        do {
            let (data, _) = try await result.itemProvider.loadItem(
                forTypeIdentifier: UTType.image.identifier,
                options: nil
            ) as! (Data, NSError?)
            self.selectedImageData = data
            self.selectedImage = UIImage(data: data)
        } catch {
            self.error = "无法加载所选图片: \(error.localizedDescription)"
        }
    }

    /// Compress image to JPEG with reasonable quality for processing.
    func compressForProcessing(_ image: UIImage, maxBytes: Int = 10_000_000) -> Data? {
        var compression: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: compression)

        while let currentData = data, currentData.count > maxBytes, compression > 0.3 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }

        return data
    }

    /// Save an image to the photo library.
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIImageWriteToSavedPhotosAlbum(
                image,
                nil, nil, nil
            )
            // Note: UIImageWriteToSavedPhotosAlbum doesn't have a modern completion API,
            // but it's the simplest approach. For production, use PHPhotoLibrary.
            continuation.resume()
        }
    }
}
