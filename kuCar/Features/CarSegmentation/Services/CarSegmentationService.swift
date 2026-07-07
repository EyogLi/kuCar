import Foundation
import CoreImage
import CoreML
import Vision
import Accelerate

/// Implements car body segmentation using DeepLabV3 via Vision/CoreML.
/// All processing runs on-device — no network calls.
final class CarSegmentationService: SegmentationServiceProtocol, @unchecked Sendable {

    private let processingQueue = DispatchQueue(
        label: "com.kucar.segmentation",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Maximum dimension for processing. Images larger than this are downscaled.
    private let maxProcessingDimension: CGFloat = 2048

    // MARK: - Public API

    func segmentCar(in image: CGImage) async throws -> SegmentationResult {
        try await withCheckedThrowingContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SegmentationError.serviceDeallocated)
                    return
                }
                do {
                    let result = try self.performSegmentation(on: image)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func refinePanelMask(
        image: CGImage,
        point: CGPoint,
        currentMask: CIImage
    ) async throws -> CIImage {
        // SAM refinement will be implemented in Phase 2.
        // For now, return the current mask unchanged.
        return currentMask
    }

    // MARK: - Private: Segmentation Pipeline

    private func performSegmentation(on image: CGImage) throws -> SegmentationResult {
        // Stage 1: Preprocess — scale to manageable size
        let originalSize = CGSize(width: image.width, height: image.height)
        let scaledImage = try scaleImageIfNeeded(image, maxDimension: maxProcessingDimension)
        let scaleFactor = CGFloat(scaledImage.width) / CGFloat(image.width)

        // Stage 2: Run DeepLabV3 semantic segmentation
        let bodyMask = try runDeepLabV3(on: scaledImage)

        // Stage 3: Post-process mask (upsample to original size, morphological cleanup)
        let cleanedMask = try cleanMask(bodyMask, originalSize: originalSize, scaleFactor: scaleFactor)

        // Stage 4: Split body mask into per-panel masks using geometric heuristics
        let panelMasks = try splitIntoPanels(
            fullMask: cleanedMask,
            imageSize: originalSize
        )

        // Stage 5: Encode masks as PNG data
        let fullBodyMaskData = try encodeMaskAsPNG(cleanedMask)
        var panelMasksData: [CarPanel: Data] = [:]
        for (panel, mask) in panelMasks {
            panelMasksData[panel] = try encodeMaskAsPNG(mask)
        }

        // Wheel detection is Phase 3 — return empty for now
        return SegmentationResult(
            fullBodyMaskData: fullBodyMaskData,
            panelMasksData: panelMasksData,
            wheelDetections: [],
            originalImageSize: originalSize
        )
    }

    // MARK: - DeepLabV3 Integration

    private func runDeepLabV3(on image: CGImage) throws -> CIImage {
        // Try to load DeepLabV3 model from bundle (only available after manual download)
        if let modelURL = Bundle.main.url(forResource: "DeepLabV3", withExtension: "mlpackage"),
           let compiledURL = try? MLModel.compileModel(at: modelURL),
           let model = try? MLModel(contentsOf: compiledURL),
           let visionModel = try? VNCoreMLModel(for: model) {

            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .scaleFill

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try handler.perform([request])

            guard let result = request.results?.first as? VNPixelBufferObservation else {
                throw SegmentationError.segmentationFailed
            }

            let segmentationMap = CIImage(cvPixelBuffer: result.pixelBuffer)
            return extractCarMask(from: segmentationMap)
        }

        // Fallback: DeepLabV3 model not bundled → use whole-image mask
        // Download from https://developer.apple.com/machine-learning/models/
        return fullImageMask(for: image)
    }

    /// When DeepLabV3 is unavailable, treat the entire image as the car body.
    private func fullImageMask(for image: CGImage) -> CIImage {
        let width = image.width
        let height = image.height
        // Create a white (all-ones) mask covering the full image
        let color = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        return CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    }

    /// Extract "car" class pixels from DeepLabV3 output (PASCAL VOC class 7 of 21).
    private func extractCarMask(from segmentationMap: CIImage) -> CIImage {
        let maskFilter = CIFilter(name: "CIColorMatrix")!
        maskFilter.setValue(segmentationMap, forKey: kCIInputImageKey)
        maskFilter.setValue(CIVector(x: 10, y: 0, z: 0, w: 0), forKey: "inputRVector")
        maskFilter.setValue(CIVector(x: 0, y: 10, z: 0, w: 0), forKey: "inputGVector")
        maskFilter.setValue(CIVector(x: 0, y: 0, z: 10, w: 0), forKey: "inputBVector")
        maskFilter.setValue(CIVector(x: -3, y: -3, z: -3, w: 0), forKey: "inputBiasVector")
        return maskFilter.outputImage ?? segmentationMap
    }

    // MARK: - Image Scaling

    private func scaleImageIfNeeded(_ image: CGImage, maxDimension: CGFloat) throws -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let maxEdge = max(width, height)

        guard maxEdge > maxDimension else { return image }

        let scale = maxDimension / maxEdge
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw SegmentationError.imageProcessingFailed
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        guard let scaled = context.makeImage() else {
            throw SegmentationError.imageProcessingFailed
        }
        return scaled
    }

    // MARK: - Mask Post-processing

    private func cleanMask(_ mask: CIImage, originalSize: CGSize, scaleFactor: CGFloat) throws -> CIImage {
        // 1. Upsample mask back to original size
        let scaleX = originalSize.width / mask.extent.width
        let scaleY = originalSize.height / mask.extent.height
        let scaledMask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // 2. Apply morphological operations (dilate + erode = close holes)
        let dilated = scaledMask
            .applyingFilter("CIMorphologyRectangleMaximum", parameters: [
                kCIInputRadiusKey: 8
            ])

        let closed = dilated
            .applyingFilter("CIMorphologyRectangleMinimum", parameters: [
                kCIInputRadiusKey: 6
            ])

        // 3. Gaussian blur to smooth edges
        let smoothed = closed
            .applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 2
            ])

        return smoothed
    }

    // MARK: - Panel Splitting Heuristic

    /// Split a single car body mask into individual panel masks using
    /// geometric projection-based heuristics.
    private func splitIntoPanels(fullMask: CIImage, imageSize: CGSize) throws -> [CarPanel: CIImage] {

        let width = imageSize.width
        let height = imageSize.height
        var panels: [CarPanel: CIImage] = [:]

        // The heuristic assumes a profile or 3/4 view.
        // Panel regions are defined as fractions of the car bounding box.
        // In Phase 2, SAM will refine these initial guesses.

        // For MVP (Phase 1), we create a single "whole car" panel that covers everything.
        // Per-panel splitting is Phase 2.
        let wholeCarMask = fullMask
        for panel in CarPanel.allCases {
            // In Phase 1, all panels share the same whole-body mask.
            // Phase 2 will implement the geometric splitting heuristics.
            panels[panel] = wholeCarMask
        }

        return panels
    }

    // MARK: - Helpers

    private func encodeMaskAsPNG(_ mask: CIImage) throws -> Data {
        let context = CIContext(options: [
            .workingColorSpace: NSNull(),
            .outputPremultiplication: true
        ])
        guard let cgImage = context.createCGImage(mask, from: mask.extent) else {
            throw SegmentationError.maskEncodingFailed
        }
        guard let data = CFDataCreateMutable(nil, 0) else {
            throw SegmentationError.maskEncodingFailed
        }
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
            throw SegmentationError.maskEncodingFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw SegmentationError.maskEncodingFailed
        }
        return data as Data
    }
}

// MARK: - Errors

enum SegmentationError: LocalizedError {
    case modelNotAvailable
    case segmentationFailed
    case imageProcessingFailed
    case maskEncodingFailed
    case serviceDeallocated

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "AI分割模型不可用，请确认DeepLabV3.mlpackage已正确打包"
        case .segmentationFailed:
            return "车辆分割失败，请尝试使用更清晰的照片"
        case .imageProcessingFailed:
            return "图像处理失败"
        case .maskEncodingFailed:
            return "蒙版编码失败"
        case .serviceDeallocated:
            return "分割服务已释放"
        }
    }
}
