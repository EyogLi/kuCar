import Foundation
import CoreGraphics
import CoreImage
import SwiftUI

// MARK: - Segmented Car (top-level model)

/// Represents a car photo with its segmentation data and user-applied modifications.
struct SegmentedCar: Codable, Identifiable, Hashable {
    let id: UUID
    let originalImageData: Data
    let segmentationResult: SegmentationResult
    var appliedColors: [CarPanel: PanelColorApplication]
    var appliedWheels: WheelApplication?
    var createdDate: Date

    init(
        id: UUID = UUID(),
        originalImageData: Data,
        segmentationResult: SegmentationResult,
        appliedColors: [CarPanel: PanelColorApplication] = [:],
        appliedWheels: WheelApplication? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.segmentationResult = segmentationResult
        self.appliedColors = appliedColors
        self.appliedWheels = appliedWheels
        self.createdDate = createdDate
    }

    /// Lazy-decoded original image.
    var originalImage: CGImage? {
        guard let dataProvider = CGDataProvider(data: originalImageData as CFData),
              let image = CGImage(
                jpegDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return nil }
        return image
    }

    // MARK: - Hashable (exclude image data for performance)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SegmentedCar, rhs: SegmentedCar) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Segmentation Result

struct SegmentationResult: Codable, Hashable {
    /// PNG-encoded binary mask of the entire car body
    let fullBodyMaskData: Data
    /// Per-panel masks stored as PNG data
    var panelMasksData: [CarPanel: Data]
    /// Detected wheel bounding boxes
    let wheelDetections: [DetectedWheel]
    /// Original image dimensions
    let originalImageSize: CGSize

    /// Decoded full-body CIImage mask
    var fullBodyMask: CIImage? {
        decodeMask(from: fullBodyMaskData)
    }

    /// Decode a specific panel's mask.
    func panelMask(for panel: CarPanel) -> CIImage? {
        guard let data = panelMasksData[panel] else { return nil }
        return decodeMask(from: data)
    }

    private func decodeMask(from data: Data) -> CIImage? {
        guard let image = CIImage(data: data, options: [.applyOrientationProperty: false]) else {
            return nil
        }
        return image
    }
}

// MARK: - Car Panel

enum CarPanel: String, Codable, CaseIterable, Hashable {
    case hood
    case roof
    case trunk
    case frontLeftDoor
    case frontRightDoor
    case rearLeftDoor
    case rearRightDoor
    case leftFender
    case rightFender
    case frontBumper
    case rearBumper
    case sideMirrors

    var displayName: String {
        switch self {
        case .hood:          return "引擎盖"
        case .roof:          return "车顶"
        case .trunk:         return "后备箱"
        case .frontLeftDoor: return "左前门"
        case .frontRightDoor:return "右前门"
        case .rearLeftDoor:  return "左后门"
        case .rearRightDoor: return "右后门"
        case .leftFender:    return "左翼子板"
        case .rightFender:   return "右翼子板"
        case .frontBumper:   return "前保险杠"
        case .rearBumper:    return "后保险杠"
        case .sideMirrors:   return "后视镜"
        }
    }

    var englishName: String {
        switch self {
        case .hood:          return "Hood"
        case .roof:          return "Roof"
        case .trunk:         return "Trunk"
        case .frontLeftDoor: return "Front Left Door"
        case .frontRightDoor:return "Front Right Door"
        case .rearLeftDoor:  return "Rear Left Door"
        case .rearRightDoor: return "Rear Right Door"
        case .leftFender:    return "Left Fender"
        case .rightFender:   return "Right Fender"
        case .frontBumper:   return "Front Bumper"
        case .rearBumper:    return "Rear Bumper"
        case .sideMirrors:   return "Side Mirrors"
        }
    }
}

// MARK: - Panel Color Application

struct PanelColorApplication: Codable, Hashable {
    let colorPreset: ColorPreset
    let finish: WrapFinish
    let intensity: Float

    init(colorPreset: ColorPreset, finish: WrapFinish = .gloss, intensity: Float = 0.85) {
        self.colorPreset = colorPreset
        self.finish = finish
        self.intensity = min(max(intensity, 0), 1)
    }
}

// MARK: - Detected Wheel

struct DetectedWheel: Codable, Identifiable, Hashable {
    let id: UUID
    let position: WheelPosition
    /// Normalized bounding box (0...1) relative to image dimensions
    let normalizedBoundingBox: CGRect
    let confidence: Float

    init(
        id: UUID = UUID(),
        position: WheelPosition,
        normalizedBoundingBox: CGRect,
        confidence: Float
    ) {
        self.id = id
        self.position = position
        self.normalizedBoundingBox = normalizedBoundingBox
        self.confidence = confidence
    }

    /// Compute center point in normalized coordinates.
    var normalizedCenter: CGPoint {
        CGPoint(
            x: normalizedBoundingBox.midX,
            y: normalizedBoundingBox.midY
        )
    }

    /// Approximate radius in normalized units.
    var normalizedRadius: CGFloat {
        min(normalizedBoundingBox.width, normalizedBoundingBox.height) / 2.0
    }
}

enum WheelPosition: String, Codable, CaseIterable, Hashable {
    case frontLeft
    case frontRight
    case rearLeft
    case rearRight

    var displayName: String {
        switch self {
        case .frontLeft:  return "左前轮"
        case .frontRight: return "右前轮"
        case .rearLeft:   return "左后轮"
        case .rearRight:  return "右后轮"
        }
    }
}

// MARK: - Wheel Application

struct WheelApplication: Codable, Hashable {
    let positions: [WheelPosition: WheelStyle]
    let fitment: WheelFitment
}

struct WheelFitment: Codable, Hashable {
    var diameter: Float       // inches (18, 19, 20...)
    var width: Float          // inches (8.5, 9.0...)
    var offset: Float         // mm
    var tireProfile: Float    // aspect ratio (35, 40, 45...)
}
