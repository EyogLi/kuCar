import Foundation

// MARK: - Built-in Color Presets

extension ColorPreset {

    /// 40+ built-in color presets for the MVP.
    static let presets: [ColorPreset] = [
        // Blues
        ColorPreset(name: "极光蓝", englishName: "Aurora Blue", hexValue: "#1E3A8A", category: .blues, colorComponents: ColorComponents(r: 0.12, g: 0.23, b: 0.54)),
        ColorPreset(name: "天蓝", englishName: "Sky Blue", hexValue: "#3B82F6", category: .blues, colorComponents: ColorComponents(r: 0.23, g: 0.51, b: 0.96)),
        ColorPreset(name: "深海蓝", englishName: "Deep Sea Blue", hexValue: "#1E40AF", category: .blues, colorComponents: ColorComponents(r: 0.12, g: 0.25, b: 0.69)),
        ColorPreset(name: "淡蓝", englishName: "Light Blue", hexValue: "#93C5FD", category: .blues, colorComponents: ColorComponents(r: 0.58, g: 0.77, b: 0.99)),
        ColorPreset(name: "青蓝", englishName: "Cyan Blue", hexValue: "#06B6D4", category: .blues, colorComponents: ColorComponents(r: 0.02, g: 0.71, b: 0.83)),

        // Reds
        ColorPreset(name: "魂动红", englishName: "Soul Red", hexValue: "#DC2626", category: .reds, colorComponents: ColorComponents(r: 0.86, g: 0.15, b: 0.15)),
        ColorPreset(name: "酒红", englishName: "Burgundy", hexValue: "#991B1B", category: .reds, colorComponents: ColorComponents(r: 0.60, g: 0.11, b: 0.11)),
        ColorPreset(name: "玫瑰红", englishName: "Rose Red", hexValue: "#F43F5E", category: .reds, colorComponents: ColorComponents(r: 0.96, g: 0.25, b: 0.37)),
        ColorPreset(name: "暗红", englishName: "Dark Red", hexValue: "#7F1D1D", category: .reds, colorComponents: ColorComponents(r: 0.50, g: 0.11, b: 0.11)),

        // Greens
        ColorPreset(name: "英伦绿", englishName: "British Racing Green", hexValue: "#166534", category: .greens, colorComponents: ColorComponents(r: 0.09, g: 0.40, b: 0.20)),
        ColorPreset(name: "薄荷绿", englishName: "Mint Green", hexValue: "#34D399", category: .greens, colorComponents: ColorComponents(r: 0.20, g: 0.83, b: 0.60)),
        ColorPreset(name: "军绿", englishName: "Army Green", hexValue: "#4D7C0F", category: .greens, colorComponents: ColorComponents(r: 0.30, g: 0.49, b: 0.06)),
        ColorPreset(name: "荧光绿", englishName: "Lime Green", hexValue: "#A3E635", category: .greens, colorComponents: ColorComponents(r: 0.64, g: 0.90, b: 0.21)),

        // Yellows
        ColorPreset(name: "太阳黄", englishName: "Sun Yellow", hexValue: "#FBBF24", category: .yellows, colorComponents: ColorComponents(r: 0.98, g: 0.75, b: 0.14)),
        ColorPreset(name: "金色", englishName: "Gold", hexValue: "#D97706", category: .yellows, colorComponents: ColorComponents(r: 0.85, g: 0.47, b: 0.02)),
        ColorPreset(name: "柠檬黄", englishName: "Lemon Yellow", hexValue: "#FEF08A", category: .yellows, colorComponents: ColorComponents(r: 0.99, g: 0.94, b: 0.54)),

        // Oranges
        ColorPreset(name: "竞速橙", englishName: "Racing Orange", hexValue: "#F97316", category: .oranges, colorComponents: ColorComponents(r: 0.98, g: 0.45, b: 0.09)),
        ColorPreset(name: "铜色", englishName: "Copper", hexValue: "#C2410C", category: .oranges, colorComponents: ColorComponents(r: 0.76, g: 0.25, b: 0.05)),
        ColorPreset(name: "杏橙", englishName: "Apricot", hexValue: "#FDBA74", category: .oranges, colorComponents: ColorComponents(r: 0.99, g: 0.73, b: 0.45)),

        // Purples
        ColorPreset(name: "皇家紫", englishName: "Royal Purple", hexValue: "#7C3AED", category: .purples, colorComponents: ColorComponents(r: 0.49, g: 0.23, b: 0.93)),
        ColorPreset(name: "薰衣草紫", englishName: "Lavender", hexValue: "#A78BFA", category: .purples, colorComponents: ColorComponents(r: 0.65, g: 0.55, b: 0.98)),
        ColorPreset(name: "深紫", englishName: "Deep Purple", hexValue: "#4C1D95", category: .purples, colorComponents: ColorComponents(r: 0.30, g: 0.11, b: 0.58)),

        // Pinks
        ColorPreset(name: "芭比粉", englishName: "Barbie Pink", hexValue: "#EC4899", category: .pinks, colorComponents: ColorComponents(r: 0.93, g: 0.28, b: 0.60)),
        ColorPreset(name: "樱花粉", englishName: "Sakura Pink", hexValue: "#F9A8D4", category: .pinks, colorComponents: ColorComponents(r: 0.98, g: 0.66, b: 0.83)),
        ColorPreset(name: "玫红", englishName: "Magenta", hexValue: "#BE185D", category: .pinks, colorComponents: ColorComponents(r: 0.75, g: 0.09, b: 0.36)),

        // Blacks / Grays
        ColorPreset(name: "曜石黑", englishName: "Obsidian Black", hexValue: "#1A1A1A", category: .blacks, colorComponents: ColorComponents(r: 0.10, g: 0.10, b: 0.10)),
        ColorPreset(name: "哑光黑", englishName: "Matte Black", hexValue: "#2D2D2D", category: .blacks, colorComponents: ColorComponents(r: 0.18, g: 0.18, b: 0.18)),
        ColorPreset(name: "石墨灰", englishName: "Graphite Gray", hexValue: "#4B5563", category: .blacks, colorComponents: ColorComponents(r: 0.29, g: 0.33, b: 0.39)),
        ColorPreset(name: "水泥灰", englishName: "Cement Gray", hexValue: "#9CA3AF", category: .silvers, colorComponents: ColorComponents(r: 0.61, g: 0.64, b: 0.69)),

        // Whites / Silvers
        ColorPreset(name: "珍珠白", englishName: "Pearl White", hexValue: "#F8FAFC", category: .whites, colorComponents: ColorComponents(r: 0.97, g: 0.98, b: 0.99)),
        ColorPreset(name: "冰川白", englishName: "Glacier White", hexValue: "#FFFFFF", category: .whites, colorComponents: ColorComponents(r: 1.0, g: 1.0, b: 1.0)),
        ColorPreset(name: "钛银", englishName: "Titanium Silver", hexValue: "#C0C0C0", category: .silvers, colorComponents: ColorComponents(r: 0.75, g: 0.75, b: 0.75)),
        ColorPreset(name: "GT银", englishName: "GT Silver", hexValue: "#A8A9AD", category: .silvers, colorComponents: ColorComponents(r: 0.66, g: 0.66, b: 0.68)),
        ColorPreset(name: "月光银", englishName: "Moonlight Silver", hexValue: "#D1D5DB", category: .silvers, colorComponents: ColorComponents(r: 0.82, g: 0.84, b: 0.86)),

        // Browns
        ColorPreset(name: "巧克力棕", englishName: "Chocolate Brown", hexValue: "#78350F", category: .browns, colorComponents: ColorComponents(r: 0.47, g: 0.21, b: 0.06)),
        ColorPreset(name: "沙棕", englishName: "Sand Brown", hexValue: "#D4A574", category: .browns, colorComponents: ColorComponents(r: 0.83, g: 0.65, b: 0.45)),
        ColorPreset(name: "咖啡棕", englishName: "Coffee Brown", hexValue: "#6F4E37", category: .browns, colorComponents: ColorComponents(r: 0.44, g: 0.31, b: 0.22)),

        // Special colors
        ColorPreset(name: "龙胆蓝", englishName: "Gentian Blue", hexValue: "#2563EB", category: .blues, colorComponents: ColorComponents(r: 0.15, g: 0.39, b: 0.92)),
        ColorPreset(name: "卡雷拉白", englishName: "Carrara White", hexValue: "#F3F4F6", category: .whites, colorComponents: ColorComponents(r: 0.95, g: 0.96, b: 0.96)),
        ColorPreset(name: "熔岩橙", englishName: "Lava Orange", hexValue: "#EA580C", category: .oranges, colorComponents: ColorComponents(r: 0.92, g: 0.35, b: 0.05)),
    ]
}
