import SwiftUI
import CoreImage
import Observation

@MainActor
@Observable
final class SegmentationViewModel {
    var isProcessing = false
    var progress: Float = 0.0
    var segmentedCar: SegmentedCar?
    var error: String?
    var showMaskPreview = false
    var maskPreviewImage: CGImage?

    private let segmentationService: SegmentationServiceProtocol
    private let wheelDetectionService: WheelDetectionServiceProtocol
    private let imageCacheManager: ImageCacheManager

    init(
        segmentationService: SegmentationServiceProtocol,
        wheelDetectionService: WheelDetectionServiceProtocol,
        imageCacheManager: ImageCacheManager
    ) {
        self.segmentationService = segmentationService
        self.wheelDetectionService = wheelDetectionService
        self.imageCacheManager = imageCacheManager
    }

    // MARK: - Actions

    func segmentImage(_ imageData: Data) async {
        isProcessing = true
        progress = 0.1
        error = nil

        guard let image = cgImage(from: imageData) else {
            error = "无法解码图片"
            isProcessing = false
            return
        }

        do {
            progress = 0.3

            // Run segmentation
            let result = try await segmentationService.segmentCar(in: image)

            progress = 0.8

            // Create SegmentedCar model
            let car = SegmentedCar(
                originalImageData: imageData,
                segmentationResult: result
            )

            // Cache the segmentation mask
            if let mask = result.fullBodyMask,
               let cgMask = renderMaskToCGImage(mask) {
                imageCacheManager.cacheImage(cgMask, for: "segmentation_\(car.id)")
            }

            segmentedCar = car
            progress = 1.0
        } catch {
            self.error = error.localizedDescription
        }

        isProcessing = false
    }

    func generateMaskPreview(for car: SegmentedCar) {
        guard let mask = car.segmentationResult.fullBodyMask else { return }
        maskPreviewImage = renderMaskToCGImage(mask)
        showMaskPreview = true
    }

    // MARK: - Helpers

    private func cgImage(from data: Data) -> CGImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                jpegDataProviderSource: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            // Try as PNG
            if let uiImage = UIImage(data: data),
               let cgImage = uiImage.cgImage {
                return cgImage
            }
            return nil
        }
        return image
    }

    private func renderMaskToCGImage(_ mask: CIImage) -> CGImage? {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        return context.createCGImage(mask, from: mask.extent)
    }
}
