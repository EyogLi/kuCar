import Foundation
import CoreImage

// MARK: - Segmentation Service

protocol SegmentationServiceProtocol: AnyObject, Sendable {
    /// Perform semantic segmentation on a car image.
    /// - Parameter image: The input car photo as CGImage.
    /// - Returns: A segmentation result containing body mask and detected wheels.
    func segmentCar(in image: CGImage) async throws -> SegmentationResult

    /// Refine a specific panel mask using a user-provided point prompt.
    /// - Parameters:
    ///   - image: The original car image.
    ///   - point: A normalized point (0...1) indicating the panel location.
    ///   - currentMask: The existing coarse mask for the panel.
    /// - Returns: A refined CIImage mask.
    func refinePanelMask(image: CGImage, point: CGPoint, currentMask: CIImage) async throws -> CIImage
}

// MARK: - Wheel Detection Service

protocol WheelDetectionServiceProtocol: AnyObject, Sendable {
    /// Detect wheel positions in a car image.
    /// - Parameter image: The input car photo.
    /// - Returns: Array of detected wheels with bounding boxes.
    func detectWheels(in image: CGImage) async throws -> [DetectedWheel]
}

// MARK: - Colorization Service

protocol ColorizationServiceProtocol: AnyObject, Sendable {
    /// Apply a color wrap to specified car panels.
    /// - Parameters:
    ///   - mask: The segmentation mask for the target panels (CIImage).
    ///   - originalImage: The original car photo.
    ///   - color: The target color preset.
    ///   - finish: The wrap finish type (gloss, matte, etc.).
    ///   - intensity: Color application intensity (0...1).
    /// - Returns: A new CIImage with the color applied.
    func applyColor(
        to mask: CIImage,
        originalImage: CIImage,
        color: ColorPreset,
        finish: WrapFinish,
        intensity: Float
    ) async throws -> CIImage

    /// Generate a full-resolution preview image.
    func generatePreview(from ciImage: CIImage, originalSize: CGSize) async throws -> CGImage
}

// MARK: - Wheel Overlay Service

protocol WheelOverlayServiceProtocol: AnyObject, Sendable {
    /// Overlay a wheel style onto a detected wheel position.
    /// - Parameters:
    ///   - wheelStyle: The wheel style to render.
    ///   - detection: The detected wheel position/size.
    ///   - originalImage: The base car image.
    /// - Returns: A composited CIImage with the new wheel.
    func overlayWheel(
        _ wheelStyle: WheelStyle,
        at detection: DetectedWheel,
        on originalImage: CIImage
    ) async throws -> CIImage
}

// MARK: - Storage / Repository

protocol ProjectStorageProtocol: Sendable {
    func saveProject(_ project: UserProject) async throws
    func loadProject(id: UUID) async throws -> UserProject?
    func deleteProject(_ project: UserProject) async throws
    func fetchAllProjects() async throws -> [UserProject]
}
