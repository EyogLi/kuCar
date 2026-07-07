import CoreImage
import UIKit

extension CIImage {

    /// Convert CIImage to CGImage for display.
    func renderToCGImage(context: CIContext = CIContext()) -> CGImage? {
        context.createCGImage(self, from: extent)
    }

    /// Convert CIImage to UIImage.
    func renderToUIImage(context: CIContext = CIContext()) -> UIImage? {
        guard let cgImage = renderToCGImage(context: context) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Resize to fit within max dimension while maintaining aspect ratio.
    func scaledToFit(maxDimension: CGFloat) -> CIImage {
        let currentSize = extent.size
        let maxEdge = max(currentSize.width, currentSize.height)

        guard maxEdge > maxDimension else { return self }

        let scale = maxDimension / maxEdge
        return transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    /// Center-crop to a target size.
    func centerCropped(to targetSize: CGSize) -> CIImage {
        let currentSize = extent.size
        let originX = (currentSize.width - targetSize.width) / 2
        let originY = (currentSize.height - targetSize.height) / 2
        return cropped(to: CGRect(origin: CGPoint(x: originX, y: originY), size: targetSize))
    }

    /// Apply a simple blur.
    func blurred(radius: Double = 5.0) -> CIImage {
        applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
    }

    /// Convert to grayscale.
    var grayscale: CIImage {
        applyingFilter("CIPhotoEffectMono")
    }
}
