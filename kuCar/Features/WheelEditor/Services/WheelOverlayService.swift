import Foundation
import CoreImage
import UIKit

/// Renders wheel style overlays onto detected wheel positions using homography
/// transforms and alpha compositing with shadow preservation.
final class WheelOverlayService: WheelOverlayServiceProtocol, @unchecked Sendable {

    private let renderQueue = DispatchQueue(
        label: "com.kucar.wheelOverlay",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private lazy var ciContext = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputPremultiplication: true
    ])

    // MARK: - Public API

    func overlayWheel(
        _ wheelStyle: WheelStyle,
        at detection: DetectedWheel,
        on originalImage: CIImage
    ) async throws -> CIImage {
        try await withCheckedThrowingContinuation { continuation in
            renderQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: originalImage)
                    return
                }
                do {
                    let result = try self.renderWheelOverlay(
                        style: wheelStyle,
                        detection: detection,
                        originalImage: originalImage
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private: Wheel Overlay Pipeline

    private func renderWheelOverlay(
        style: WheelStyle,
        detection: DetectedWheel,
        originalImage: CIImage
    ) throws -> CIImage {

        // Step 1: Load wheel asset image
        guard let wheelImage = loadWheelAsset(named: style.assetName) else {
            throw WheelOverlayError.assetNotFound(style.assetName)
        }

        // Step 2: Compute the target rect in image coordinates
        let imageSize = originalImage.extent.size
        let targetRect = denormalize(detection.normalizedBoundingBox, to: imageSize)

        // Step 3: Scale wheel asset to match target size
        let scaledWheel = scaleWheel(wheelImage, to: targetRect.size)

        // Step 4: Apply perspective warp if the wheel is viewed from an angle
        let aspectRatio = detection.normalizedBoundingBox.width / detection.normalizedBoundingBox.height
        let warpedWheel = applyPerspectiveTransform(to: scaledWheel, aspectRatio: aspectRatio)

        // Step 5: Position the wheel at the correct location
        let positionedWheel = warpedWheel.transformed(
            by: CGAffineTransform(
                translationX: targetRect.origin.x,
                y: targetRect.origin.y
            )
        )

        // Step 6: Extract and preserve original shadows around the wheel area
        let shadowMask = extractShadow(
            from: originalImage,
            around: targetRect,
            padding: 0.15
        )

        // Step 7: Composite new wheel onto original image
        let composited = compositeWheel(positionedWheel, onto: originalImage)

        // Step 8: Blend original shadows over the new wheel
        let withShadow = blendShadow(shadowMask, over: composited, in: targetRect)

        return withShadow
    }

    // MARK: - Asset Loading

    private func loadWheelAsset(named name: String) -> CIImage? {
        // Try loading from WheelAssets bundle directory
        guard let assetURL = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "WheelAssets"
        ) else {
            // Try from main bundle
            guard let path = Bundle.main.path(forResource: name, ofType: "png") else {
                return nil
            }
            return CIImage(contentsOf: URL(fileURLWithPath: path))
        }
        return CIImage(contentsOf: assetURL)
    }

    // MARK: - Coordinate Helpers

    private func denormalize(_ normalizedRect: CGRect, to size: CGSize) -> CGRect {
        CGRect(
            x: normalizedRect.origin.x * size.width,
            y: (1.0 - normalizedRect.origin.y - normalizedRect.height) * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
    }

    // MARK: - Scaling

    private func scaleWheel(_ wheelImage: CIImage, to targetSize: CGSize) -> CIImage {
        let currentExtent = wheelImage.extent
        let scaleX = targetSize.width / currentExtent.width
        let scaleY = targetSize.height / currentExtent.height
        let scale = max(scaleX, scaleY) // scale-to-fill

        return wheelImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    // MARK: - Perspective Transform

    private func applyPerspectiveTransform(to image: CIImage, aspectRatio: CGFloat) -> CIImage {
        // If aspect ratio is significantly different from 1.0,
        // the wheel is viewed from an angle and needs perspective correction

        guard aspectRatio < 0.95 || aspectRatio > 1.05 else {
            return image
        }

        let compressionFactor = min(aspectRatio, 1.0 / aspectRatio)
        let squeeze = max(compressionFactor, 0.5) // don't over-compress

        // Apply a simple scale transform in one dimension to simulate perspective
        var transform = CATransform3DIdentity
        if aspectRatio < 1.0 {
            // Wider than tall — compress horizontally
            transform = CATransform3DScale(transform, squeeze, 1.0, 1.0)
        } else {
            // Taller than wide — compress vertically
            transform = CATransform3DScale(transform, 1.0, squeeze, 1.0)
        }

        return image.applyingFilter("CIPerspectiveTransform", parameters: [
            "inputTopLeft": CIVector(x: 0, y: 0),
            "inputTopRight": CIVector(x: image.extent.width, y: 0),
            "inputBottomRight": CIVector(
                x: image.extent.width * squeeze,
                y: image.extent.height
            ),
            "inputBottomLeft": CIVector(
                x: image.extent.width * (1 - squeeze),
                y: image.extent.height
            )
        ])
    }

    // MARK: - Shadow Preservation

    private func extractShadow(
        from image: CIImage,
        around rect: CGRect,
        padding: CGFloat
    ) -> CIImage {
        // Expand the rect to include shadow area around the wheel
        let expandedRect = rect.insetBy(
            dx: -rect.width * padding,
            dy: -rect.height * padding
        )

        // Crop to expanded area
        let cropped = image.cropped(to: expandedRect)

        // Convert to grayscale to extract luminance (shadow information)
        return cropped
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 0.5
            ])
            .applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 8
            ])
    }

    // MARK: - Compositing

    private func compositeWheel(_ wheel: CIImage, onto background: CIImage) -> CIImage {
        guard let composite = CIFilter(name: "CISourceOverCompositing") else {
            return background
        }
        composite.setValue(wheel, forKey: kCIInputImageKey)
        composite.setValue(background, forKey: kCIInputBackgroundImageKey)
        return composite.outputImage ?? background
    }

    private func blendShadow(_ shadow: CIImage, over image: CIImage, in rect: CGRect) -> CIImage {
        guard let multiplyBlend = CIFilter(name: "CIMultiplyBlendMode") else {
            return image
        }
        multiplyBlend.setValue(shadow, forKey: kCIInputImageKey)
        multiplyBlend.setValue(image, forKey: kCIInputBackgroundImageKey)
        return multiplyBlend.outputImage ?? image
    }
}

// MARK: - Errors

enum WheelOverlayError: LocalizedError {
    case assetNotFound(String)

    var errorDescription: String? {
        switch self {
        case .assetNotFound(let name):
            return "轮毂素材未找到: \(name)"
        }
    }
}
