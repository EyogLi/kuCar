import Foundation
import SwiftData

// MARK: - User Project (SwiftData Model)

@Model
final class UserProject {
    @Attribute(.unique) var id: UUID
    var name: String
    var thumbnailData: Data?
    var createdDate: Date
    var modifiedDate: Date
    /// JSON-encoded SegmentedCar data
    var segmentedCarData: Data
    var isBuiltInCar: Bool
    var builtInCarID: String?

    init(
        id: UUID = UUID(),
        name: String,
        thumbnailData: Data? = nil,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        segmentedCarData: Data = Data(),
        isBuiltInCar: Bool = false,
        builtInCarID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.thumbnailData = thumbnailData
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.segmentedCarData = segmentedCarData
        self.isBuiltInCar = isBuiltInCar
        self.builtInCarID = builtInCarID
    }
}

// MARK: - Car Catalog Entry

struct CarCatalogEntry: Codable, Identifiable, Hashable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let generation: String?
    let bodyStyle: CarBodyStyle
    let referenceImageName: String
    let wheelbase: Float                    // mm
    let thumbnailName: String
    let knownWheelPositions: [WheelPosition: NormalizedRect]?
    let panelBoundaries: [CarPanel: NormalizedRect]?
    let availableColors: [String]

    var displayName: String {
        "\(make) \(model) (\(String(year)))"
    }
}

struct NormalizedRect: Codable, Hashable {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
}

enum CarBodyStyle: String, Codable, CaseIterable {
    case sedan
    case coupe
    case hatchback
    case suv
    case truck
    case van
    case convertible
    case sportsCar
    case wagon

    var displayName: String {
        switch self {
        case .sedan:       return "轿车"
        case .coupe:       return "轿跑"
        case .hatchback:   return "掀背车"
        case .suv:         return "SUV"
        case .truck:       return "皮卡"
        case .van:         return "MPV"
        case .convertible: return "敞篷"
        case .sportsCar:   return "跑车"
        case .wagon:       return "旅行车"
        }
    }
}

// MARK: - Export Configuration

struct ExportConfiguration: Codable {
    var resolution: ExportResolution
    var format: ExportFormat
    var includeWatermark: Bool
    var includeMetadata: Bool

    static let `default` = ExportConfiguration(
        resolution: .full,
        format: .jpeg,
        includeWatermark: true,
        includeMetadata: true
    )
}

enum ExportResolution: String, Codable, CaseIterable {
    case full = "原图尺寸"
    case hd = "HD (1920px)"
    case sd = "SD (1024px)"

    var maxDimension: Int? {
        switch self {
        case .full: return nil // no limit
        case .hd:   return 1920
        case .sd:   return 1024
        }
    }
}

enum ExportFormat: String, Codable, CaseIterable {
    case jpeg
    case png
    case heic

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png:  return "png"
        case .heic: return "heic"
        }
    }
}
