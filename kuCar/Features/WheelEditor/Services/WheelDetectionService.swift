import Foundation
import CoreImage
import Vision
import CoreML

/// Detects wheel positions in car images using a custom-trained YOLO-based
/// CoreML object detection model. In Phase 3, this will use WheelDetector.mlpackage.
/// For now (Phase 1-2), it provides a geometry-based fallback.
final class WheelDetectionService: WheelDetectionServiceProtocol, @unchecked Sendable {

    private let processingQueue = DispatchQueue(
        label: "com.kucar.wheelDetection",
        qos: .userInitiated,
        attributes: .concurrent
    )

    // MARK: - Public API

    func detectWheels(in image: CGImage) async throws -> [DetectedWheel] {
        try await withCheckedThrowingContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                do {
                    let detections = try self.performWheelDetection(on: image)
                    continuation.resume(returning: detections)
                } catch {
                    // Fallback: Use geometry-based estimation if ML model isn't available
                    let fallback = self.geometryBasedFallback(for: image)
                    continuation.resume(returning: fallback)
                }
            }
        }
    }

    // MARK: - Private: ML-Based Detection

    private func performWheelDetection(on image: CGImage) throws -> [DetectedWheel] {
        // Try to load the custom WheelDetector model from bundle
        guard let modelURL = Bundle.main.url(forResource: "WheelDetector", withExtension: "mlpackage"),
              let compiledURL = try? MLModel.compileModel(at: modelURL),
              let model = try? MLModel(contentsOf: compiledURL),
              let visionModel = try? VNCoreMLModel(for: model) else {
            throw WheelDetectionError.modelNotAvailable
        }

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFit

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            throw WheelDetectionError.detectionFailed
        }

        let imageSize = CGSize(width: image.width, height: image.height)

        return observations
            .filter { $0.confidence > 0.5 }
            .enumerated()
            .map { index, observation in
                let boundingBox = VNImageRectForNormalizedRect(
                    observation.boundingBox,
                    Int(imageSize.width),
                    Int(imageSize.height)
                )

                // Map position based on horizontal position in image
                let position: WheelPosition = {
                    let midX = observation.boundingBox.midX
                    let midY = observation.boundingBox.midY
                    if midY < 0.5 {
                        return midX < 0.5 ? .frontLeft : .frontRight
                    } else {
                        return midX < 0.5 ? .rearLeft : .rearRight
                    }
                }()

                return DetectedWheel(
                    position: position,
                    normalizedBoundingBox: observation.boundingBox,
                    confidence: observation.confidence
                )
            }
    }

    // MARK: - Geometry-Based Fallback

    /// When the ML model is not available, estimate wheel positions using
    /// geometric heuristics based on the assumption that wheels are near
    /// the bottom of the car body.
    private func geometryBasedFallback(for image: CGImage) -> [DetectedWheel] {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        // Assume car is centered in the lower 60% of the image
        // Wheel positions are estimated fractions of image dimensions
        let wheelPositions: [(WheelPosition, CGRect)] = [
            (.frontLeft,  CGRect(x: 0.08, y: 0.60, width: 0.16, height: 0.22)),
            (.frontRight, CGRect(x: 0.76, y: 0.60, width: 0.16, height: 0.22)),
            (.rearLeft,   CGRect(x: 0.38, y: 0.62, width: 0.14, height: 0.20)),
            (.rearRight,  CGRect(x: 0.48, y: 0.62, width: 0.14, height: 0.20)),
        ]

        return wheelPositions.map { position, normalizedRect in
            DetectedWheel(
                position: position,
                normalizedBoundingBox: normalizedRect,
                confidence: 0.6 // Lower confidence for heuristic estimation
            )
        }
    }
}

enum WheelDetectionError: LocalizedError {
    case modelNotAvailable
    case detectionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "轮毂检测模型不可用，将使用几何估算"
        case .detectionFailed:
            return "轮毂检测失败"
        }
    }
}
