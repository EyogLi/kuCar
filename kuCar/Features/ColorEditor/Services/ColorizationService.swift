import Foundation
import CoreImage
import Metal
import UIKit

/// Applies color wrap effects to car panels using Core Image filters and Metal shaders.
/// All processing is done locally — no network calls.
final class ColorizationService: ColorizationServiceProtocol, @unchecked Sendable {

    private let renderQueue = DispatchQueue(
        label: "com.kucar.colorization",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private lazy var ciContext: CIContext = {
        CIContext(options: [
            .workingColorSpace: NSNull(),
            .outputPremultiplication: true,
            .highQualityDownsample: true
        ])
    }()

    // MARK: - Public API

    func applyColor(
        to mask: CIImage,
        originalImage: CIImage,
        color: ColorPreset,
        finish: WrapFinish,
        intensity: Float
    ) async throws -> CIImage {
        try await withCheckedThrowingContinuation { continuation in
            renderQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ColorizationError.serviceDeallocated)
                    return
                }
                do {
                    let result = self.renderColorWrap(
                        mask: mask,
                        original: originalImage,
                        color: color,
                        finish: finish,
                        intensity: intensity
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func generatePreview(from ciImage: CIImage, originalSize: CGSize) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            renderQueue.async { [weak self] in
                guard let self = self else { return }
                guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                    continuation.resume(throwing: ColorizationError.renderFailed)
                    return
                }
                continuation.resume(returning: cgImage)
            }
        }
    }

    // MARK: - Private: Color Wrap Rendering Pipeline

    private func renderColorWrap(
        mask: CIImage,
        original: CIImage,
        color: ColorPreset,
        finish: WrapFinish,
        intensity: Float
    ) -> CIImage {

        // Step 1: Build the tinted layer
        let tintedLayer = applyBaseColorTint(to: original, color: color, intensity: intensity)

        // Step 2: Blend tinted layer with original using the panel mask
        let maskedBlend = blendWithMask(
            foreground: tintedLayer,
            background: original,
            mask: mask
        )

        // Step 3: Apply paint finish (gloss/matte/satin/metallic/chrome)
        let withFinish = applyFinish(to: maskedBlend, finish: finish, originalImage: original, mask: mask)

        // Step 4: Preserve original specular highlights
        let withHighlights = preserveHighlights(original: original, modified: withFinish, mask: mask)

        return withHighlights
    }

    // MARK: - Step 1: Base Color Tint

    private func applyBaseColorTint(to image: CIImage, color: ColorPreset, intensity: Float) -> CIImage {
        // Convert the image to grayscale first to extract luminance
        guard let monoFilter = CIFilter(name: "CIColorMatrix") else { return image }

        monoFilter.setValue(image, forKey: kCIInputImageKey)
        // Standard luminance weights
        monoFilter.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputRVector")
        monoFilter.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputGVector")
        monoFilter.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputBVector")
        monoFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        monoFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let grayscale = monoFilter.outputImage else { return image }

        // Multiply target color by luminance to create tinted layer
        guard let tintFilter = CIFilter(name: "CIColorMatrix") else { return image }
        tintFilter.setValue(grayscale, forKey: kCIInputImageKey)
        tintFilter.setValue(CIVector(
            x: CGFloat(color.redComponent * intensity),
            y: 0, z: 0, w: 0
        ), forKey: "inputRVector")
        tintFilter.setValue(CIVector(
            x: 0,
            y: CGFloat(color.greenComponent * intensity),
            z: 0, w: 0
        ), forKey: "inputGVector")
        tintFilter.setValue(CIVector(
            x: 0, y: 0,
            z: CGFloat(color.blueComponent * intensity),
            w: 0
        ), forKey: "inputBVector")
        tintFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

        return tintFilter.outputImage ?? image
    }

    // MARK: - Step 2: Blend with Mask

    private func blendWithMask(foreground: CIImage, background: CIImage, mask: CIImage) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return foreground
        }
        blendFilter.setValue(foreground, forKey: kCIInputImageKey)
        blendFilter.setValue(background, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        return blendFilter.outputImage ?? foreground
    }

    // MARK: - Step 3: Paint Finish

    private func applyFinish(
        to image: CIImage,
        finish: WrapFinish,
        originalImage: CIImage,
        mask: CIImage
    ) -> CIImage {
        let params = MaterialParameter.from(finish: finish)

        switch finish {
        case .gloss:
            return applyGlossFinish(to: image, params: params, original: originalImage)
        case .matte:
            return applyMatteFinish(to: image, params: params)
        case .satin:
            return applySatinFinish(to: image, params: params)
        case .metallic:
            return applyMetallicFinish(to: image, params: params)
        case .chrome:
            return applyChromeFinish(to: image, params: params, original: originalImage)
        case .pearl, .carbonFiber, .brushedMetal:
            // Phase 2 finishes — fall back to satin for now
            return applySatinFinish(to: image, params: params)
        }
    }

    private func applyGlossFinish(to image: CIImage, params: MaterialParameter, original: CIImage) -> CIImage {
        // Increase contrast and saturation for glossy look
        let contrastAdjusted = image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.15,
                kCIInputSaturationKey: 1.1
            ])
        // Sharpen
        let sharpened = contrastAdjusted
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.3
            ])
        return sharpened
    }

    private func applyMatteFinish(to image: CIImage, params: MaterialParameter) -> CIImage {
        // Reduce contrast, add subtle noise grain
        let contrastAdjusted = image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 0.85,
                kCIInputSaturationKey: 0.9,
                kCIInputBrightnessKey: 0.02
            ])
        // Add subtle noise for matte texture
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else {
            return contrastAdjusted
        }
        let noise = noiseFilter.outputImage?
            .applyingFilter("CIAreaAverage", parameters: [
                kCIInputExtentKey: CIVector(
                    x: 0, y: 0,
                    z: image.extent.width,
                    w: image.extent.height
                )
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.02),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0.02),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0.02),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ]) ?? contrastAdjusted

        guard let addBlend = CIFilter(name: "CIAdditionCompositing") else {
            return contrastAdjusted
        }
        addBlend.setValue(contrastAdjusted, forKey: kCIInputImageKey)
        addBlend.setValue(noise, forKey: kCIInputBackgroundImageKey)
        return addBlend.outputImage ?? contrastAdjusted
    }

    private func applySatinFinish(to image: CIImage, params: MaterialParameter) -> CIImage {
        // Medium gloss — between gloss and matte
        image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.05,
                kCIInputSaturationKey: 1.0
            ])
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.15
            ])
    }

    private func applyMetallicFinish(to image: CIImage, params: MaterialParameter) -> CIImage {
        // Increase contrast and add metallic sheen
        let contrasted = image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.2,
                kCIInputSaturationKey: 0.85
            ])
        // Add micro-flake noise (metallic sparkle)
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return contrasted }
        let noise = noiseFilter.outputImage?
            .applyingFilter("CIZoomBlur", parameters: [
                kCIInputAmountKey: 2,
                "inputCenter": CIVector(x: image.extent.midX, y: image.extent.midY)
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.05),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ]) ?? contrasted

        guard let addBlend = CIFilter(name: "CIAdditionCompositing") else { return contrasted }
        addBlend.setValue(contrasted, forKey: kCIInputImageKey)
        addBlend.setValue(noise, forKey: kCIInputBackgroundImageKey)
        return addBlend.outputImage ?? contrasted
    }

    private func applyChromeFinish(
        to image: CIImage,
        params: MaterialParameter,
        original: CIImage
    ) -> CIImage {
        // Chrome: high contrast + boosted reflections from original
        let contrasted = image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.5,
                kCIInputSaturationKey: 0.3,
                kCIInputBrightnessKey: 0.1
            ])
        // Blend original specular reflections
        guard let overlayFilter = CIFilter(name: "CISoftLightBlendMode") else { return contrasted }
        overlayFilter.setValue(contrasted, forKey: kCIInputImageKey)
        overlayFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        return overlayFilter.outputImage ?? contrasted
    }

    // MARK: - Step 4: Highlight Preservation

    private func preserveHighlights(original: CIImage, modified: CIImage, mask: CIImage) -> CIImage {
        // Extract highlights from original
        let highlights = original
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 2.0,
                kCIInputBrightnessKey: -0.3
            ])
            .applyingFilter("CIMaskToAlpha")

        // Screen blend highlights over modified image within mask area
        guard let screenFilter = CIFilter(name: "CIScreenBlendMode") else { return modified }
        screenFilter.setValue(highlights, forKey: kCIInputImageKey)
        screenFilter.setValue(modified, forKey: kCIInputBackgroundImageKey)
        return screenFilter.outputImage ?? modified
    }
}

// MARK: - Errors

enum ColorizationError: LocalizedError {
    case serviceDeallocated
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .serviceDeallocated: return "着色服务已释放"
        case .renderFailed: return "渲染失败"
        }
    }
}
