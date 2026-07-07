import Foundation

/// Provides access to the built-in car model catalog.
/// Data is loaded from a bundled JSON file.
@MainActor
final class CarCatalogRepository: ObservableObject {

    @Published private(set) var entries: [CarCatalogEntry] = []
    @Published private(set) var isLoading = false

    init() {
        loadCatalog()
    }

    // MARK: - Loading

    private func loadCatalog() {
        isLoading = true
        defer { isLoading = false }

        guard let url = Bundle.main.url(
            forResource: "car_database",
            withExtension: "json",
            subdirectory: "CarDatabase"
        ) else {
            entries = Self.fallbackEntries
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            entries = try decoder.decode([CarCatalogEntry].self, from: data)
        } catch {
            print("Failed to load car catalog: \(error.localizedDescription)")
            entries = Self.fallbackEntries
        }
    }

    // MARK: - Queries

    func entries(for bodyStyle: CarBodyStyle) -> [CarCatalogEntry] {
        entries.filter { $0.bodyStyle == bodyStyle }
    }

    func entry(withID id: String) -> CarCatalogEntry? {
        entries.first { $0.id == id }
    }

    func search(query: String) -> [CarCatalogEntry] {
        let lowercased = query.lowercased()
        return entries.filter {
            $0.make.lowercased().contains(lowercased) ||
            $0.model.lowercased().contains(lowercased) ||
            $0.displayName.lowercased().contains(lowercased)
        }
    }

    func groupedByBodyStyle() -> [CarBodyStyle: [CarCatalogEntry]] {
        Dictionary(grouping: entries, by: \.bodyStyle)
    }

    // MARK: - Fallback Data (MVP 10 cars)

    static let fallbackEntries: [CarCatalogEntry] = [
        CarCatalogEntry(
            id: "toyota_camry_2024", make: "Toyota", model: "Camry", year: 2024,
            generation: "XV80", bodyStyle: .sedan, referenceImageName: "toyota_camry_2024",
            wheelbase: 2825, thumbnailName: "thumb_toyota_camry_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["珍珠白", "幻影黑", "钛银"]
        ),
        CarCatalogEntry(
            id: "honda_civic_2024", make: "Honda", model: "Civic", year: 2024,
            generation: "11th Gen", bodyStyle: .sedan, referenceImageName: "honda_civic_2024",
            wheelbase: 2735, thumbnailName: "thumb_honda_civic_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["珍珠白", "水晶黑", "金属灰"]
        ),
        CarCatalogEntry(
            id: "bmw_3series_2024", make: "BMW", model: "3 Series", year: 2024,
            generation: "G20 LCI", bodyStyle: .sedan, referenceImageName: "bmw_3series_2024",
            wheelbase: 2851, thumbnailName: "thumb_bmw_3series_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["矿石白", "蓝宝石黑", "墨尔本红"]
        ),
        CarCatalogEntry(
            id: "tesla_model3_2024", make: "Tesla", model: "Model 3", year: 2024,
            generation: "Highland", bodyStyle: .sedan, referenceImageName: "tesla_model3_2024",
            wheelbase: 2875, thumbnailName: "thumb_tesla_model3_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["珍珠白", "深蓝", "隐形灰"]
        ),
        CarCatalogEntry(
            id: "porsche_911_2024", make: "Porsche", model: "911", year: 2024,
            generation: "992.2", bodyStyle: .sportsCar, referenceImageName: "porsche_911_2024",
            wheelbase: 2450, thumbnailName: "thumb_porsche_911_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["GT银", "卡雷拉白", "龙胆蓝"]
        ),
        CarCatalogEntry(
            id: "ford_mustang_2024", make: "Ford", model: "Mustang", year: 2024,
            generation: "S650", bodyStyle: .coupe, referenceImageName: "ford_mustang_2024",
            wheelbase: 2720, thumbnailName: "thumb_ford_mustang_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["竞速红", "暗夜黑", "掠夺蓝"]
        ),
        CarCatalogEntry(
            id: "toyota_rav4_2024", make: "Toyota", model: "RAV4", year: 2024,
            generation: "XA50", bodyStyle: .suv, referenceImageName: "toyota_rav4_2024",
            wheelbase: 2690, thumbnailName: "thumb_toyota_rav4_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["珍珠白", "灰金属", "月岩"]
        ),
        CarCatalogEntry(
            id: "mercedes_cclass_2024", make: "Mercedes-Benz", model: "C-Class", year: 2024,
            generation: "W206", bodyStyle: .sedan, referenceImageName: "mercedes_cclass_2024",
            wheelbase: 2865, thumbnailName: "thumb_mercedes_cclass_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["极地白", "曜石黑", "石墨灰"]
        ),
        CarCatalogEntry(
            id: "audi_a4_2024", make: "Audi", model: "A4", year: 2024,
            generation: "B9.5", bodyStyle: .sedan, referenceImageName: "audi_a4_2024",
            wheelbase: 2820, thumbnailName: "thumb_audi_a4_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["冰川白", "神话黑", "纳瓦拉蓝"]
        ),
        CarCatalogEntry(
            id: "mazda_mx5_2024", make: "Mazda", model: "MX-5 Miata", year: 2024,
            generation: "ND3", bodyStyle: .convertible, referenceImageName: "mazda_mx5_2024",
            wheelbase: 2310, thumbnailName: "thumb_mazda_mx5_2024",
            knownWheelPositions: nil, panelBoundaries: nil, availableColors: ["魂动红", "陶瓷白", "钢琴黑"]
        ),
    ]
}
