import Foundation
import SwiftUI

// MARK: - Color Preset

struct ColorPreset: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let englishName: String
    let hexValue: String
    let category: ColorCategory

    /// RGBA components for image processing (0...1)
    var redComponent: Float { colorComponents.r }
    var greenComponent: Float { colorComponents.g }
    var blueComponent: Float { colorComponents.b }

    private let colorComponents: ColorComponents

    init(
        id: UUID = UUID(),
        name: String,
        englishName: String,
        hexValue: String,
        category: ColorCategory,
        colorComponents: ColorComponents
    ) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.hexValue = hexValue
        self.category = category
        self.colorComponents = colorComponents
    }

    /// SwiftUI Color representation.
    var swiftUIColor: Color {
        Color(
            red: Double(colorComponents.r),
            green: Double(colorComponents.g),
            blue: Double(colorComponents.b)
        )
    }

    /// CoreGraphics CGColor representation.
    var cgColor: CGColor {
        CGColor(
            red: CGFloat(colorComponents.r),
            green: CGFloat(colorComponents.g),
            blue: CGFloat(colorComponents.b),
            alpha: 1.0
        )
    }
}

struct ColorComponents: Codable, Hashable {
    let r: Float
    let g: Float
    let b: Float
}

enum ColorCategory: String, Codable, CaseIterable {
    case blues
    case reds
    case greens
    case yellows
    case oranges
    case purples
    case pinks
    case blacks
    case whites
    case silvers
    case browns
    case custom

    var displayName: String {
        switch self {
        case .blues:   return "蓝色系"
        case .reds:    return "红色系"
        case .greens:  return "绿色系"
        case .yellows: return "黄色系"
        case .oranges: return "橙色系"
        case .purples: return "紫色系"
        case .pinks:   return "粉色系"
        case .blacks:  return "黑色系"
        case .whites:  return "白色系"
        case .silvers: return "银色系"
        case .browns:  return "棕色系"
        case .custom:  return "自定义"
        }
    }
}

// MARK: - Wrap Finish

enum WrapFinish: String, Codable, CaseIterable, Hashable {
    case gloss
    case matte
    case satin
    case metallic
    case chrome
    case pearl
    case carbonFiber
    case brushedMetal

    var displayName: String {
        switch self {
        case .gloss:        return "光泽"
        case .matte:        return "哑光"
        case .satin:        return "缎面"
        case .metallic:     return "金属"
        case .chrome:       return "镀铬"
        case .pearl:        return "珠光"
        case .carbonFiber:  return "碳纤维"
        case .brushedMetal: return "拉丝金属"
        }
    }

    /// Roughness parameter for PBR shader (0 = perfectly smooth, 1 = perfectly rough)
    var roughness: Float {
        switch self {
        case .gloss:        return 0.1
        case .matte:        return 0.8
        case .satin:        return 0.35
        case .metallic:     return 0.15
        case .chrome:       return 0.05
        case .pearl:        return 0.2
        case .carbonFiber:  return 0.3
        case .brushedMetal: return 0.25
        }
    }

    /// Metallic parameter for PBR shader (0 = dielectric, 1 = fully metallic)
    var metallic: Float {
        switch self {
        case .gloss:        return 0.0
        case .matte:        return 0.0
        case .satin:        return 0.1
        case .metallic:     return 0.9
        case .chrome:       return 1.0
        case .pearl:        return 0.2
        case .carbonFiber:  return 0.0
        case .brushedMetal: return 0.8
        }
    }

    /// Which finishes are available in MVP (Phase 1)
    var isPhase1Available: Bool {
        switch self {
        case .gloss, .matte, .satin: return true
        default: return false
        }
    }
}

// MARK: - Material Parameters

struct MaterialParameter: Codable, Hashable {
    var roughness: Float
    var metallic: Float
    var clearcoat: Float     // 0...1
    var specularIntensity: Float

    static func from(finish: WrapFinish) -> MaterialParameter {
        MaterialParameter(
            roughness: finish.roughness,
            metallic: finish.metallic,
            clearcoat: finish == .gloss ? 1.0 : 0.3,
            specularIntensity: finish == .chrome ? 1.0 : 0.5
        )
    }
}
