import Foundation

// MARK: - Wheel Style

struct WheelStyle: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let englishName: String
    let brand: String
    let category: WheelCategory
    let availableSizes: [Float]        // [18, 19, 20]
    let finish: WheelFinish
    let assetName: String              // PNG file name in WheelAssets/
    let thumbnailName: String          // thumbnail in asset catalog

    init(
        id: UUID = UUID(),
        name: String,
        englishName: String,
        brand: String = "",
        category: WheelCategory,
        availableSizes: [Float] = [18, 19, 20],
        finish: WheelFinish,
        assetName: String,
        thumbnailName: String
    ) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.brand = brand
        self.category = category
        self.availableSizes = availableSizes
        self.finish = finish
        self.assetName = assetName
        self.thumbnailName = thumbnailName
    }
}

// MARK: - Wheel Category

enum WheelCategory: String, Codable, CaseIterable {
    case sport
    case luxury
    case offroad
    case vintage
    case racing
    case oem

    var displayName: String {
        switch self {
        case .sport:   return "运动"
        case .luxury:  return "豪华"
        case .offroad: return "越野"
        case .vintage: return "复古"
        case .racing:  return "赛道"
        case .oem:     return "原厂"
        }
    }
}

// MARK: - Wheel Finish

enum WheelFinish: String, Codable, CaseIterable {
    case silver
    case black
    case gunmetal
    case chrome
    case bronze
    case gold
    case white

    var displayName: String {
        switch self {
        case .silver:   return "银色"
        case .black:    return "黑色"
        case .gunmetal: return "枪灰"
        case .chrome:   return "镀铬"
        case .bronze:   return "铜色"
        case .gold:     return "金色"
        case .white:    return "白色"
        }
    }
}

// MARK: - Wheel Asset Metadata

struct WheelAssetMetadata: Codable {
    let defaultDiameter: Float      // inches
    let defaultWidth: Float         // inches
    let defaultOffset: Float        // mm
    let lugCount: Int
    let centerBore: Float           // mm
    let weight: Float?              // lbs
}
