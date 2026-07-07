import Foundation

// MARK: - Built-in Wheel Styles

extension WheelStyle {

    /// 20 built-in wheel styles for the MVP.
    static let builtInStyles: [WheelStyle] = [
        // Sport
        WheelStyle(name: "运动五辐", englishName: "Sport 5-Spoke", brand: "kuCar", category: .sport, finish: .silver, assetName: "wheel_sport_5spoke", thumbnailName: "thumb_wheel_sport_5spoke"),
        WheelStyle(name: "运动双五辐", englishName: "Sport Split-Spoke", brand: "kuCar", category: .sport, finish: .gunmetal, assetName: "wheel_sport_splitspoke", thumbnailName: "thumb_wheel_sport_splitspoke"),
        WheelStyle(name: "刀锋", englishName: "Blade", brand: "kuCar", category: .sport, finish: .black, assetName: "wheel_blade", thumbnailName: "thumb_wheel_blade"),
        WheelStyle(name: "涡轮", englishName: "Turbofan", brand: "kuCar", category: .racing, finish: .silver, assetName: "wheel_turbofan", thumbnailName: "thumb_wheel_turbofan"),

        // Luxury
        WheelStyle(name: "豪华多辐", englishName: "Luxury Multi-Spoke", brand: "kuCar", category: .luxury, finish: .chrome, assetName: "wheel_luxury_multispoke", thumbnailName: "thumb_wheel_luxury_multispoke"),
        WheelStyle(name: "豪华十辐", englishName: "Luxury 10-Spoke", brand: "kuCar", category: .luxury, finish: .silver, assetName: "wheel_luxury_10spoke", thumbnailName: "thumb_wheel_luxury_10spoke"),
        WheelStyle(name: "经典网格", englishName: "Classic Mesh", brand: "kuCar", category: .luxury, finish: .chrome, assetName: "wheel_classic_mesh", thumbnailName: "thumb_wheel_classic_mesh"),
        WheelStyle(name: "优雅星型", englishName: "Elegant Star", brand: "kuCar", category: .luxury, finish: .gunmetal, assetName: "wheel_elegant_star", thumbnailName: "thumb_wheel_elegant_star"),

        // Black/Dark
        WheelStyle(name: "哑光黑五辐", englishName: "Matte Black 5-Spoke", brand: "kuCar", category: .sport, finish: .black, assetName: "wheel_matte_black_5spoke", thumbnailName: "thumb_wheel_matte_black_5spoke"),
        WheelStyle(name: "暗夜之星", englishName: "Night Star", brand: "kuCar", category: .sport, finish: .black, assetName: "wheel_night_star", thumbnailName: "thumb_wheel_night_star"),

        // Off-road
        WheelStyle(name: "越野者", englishName: "Off-Roader", brand: "kuCar", category: .offroad, finish: .gunmetal, assetName: "wheel_offroader", thumbnailName: "thumb_wheel_offroader"),
        WheelStyle(name: "拉力之星", englishName: "Rally Star", brand: "kuCar", category: .offroad, finish: .bronze, assetName: "wheel_rally_star", thumbnailName: "thumb_wheel_rally_star"),
        WheelStyle(name: "卡车之星", englishName: "Truck Star", brand: "kuCar", category: .offroad, finish: .silver, assetName: "wheel_truck_star", thumbnailName: "thumb_wheel_truck_star"),

        // Vintage
        WheelStyle(name: "复古钢丝", englishName: "Vintage Wire", brand: "kuCar", category: .vintage, finish: .chrome, assetName: "wheel_vintage_wire", thumbnailName: "thumb_wheel_vintage_wire"),
        WheelStyle(name: "复古盘式", englishName: "Vintage Dish", brand: "kuCar", category: .vintage, finish: .silver, assetName: "wheel_vintage_dish", thumbnailName: "thumb_wheel_vintage_dish"),
        WheelStyle(name: "经典BBS风", englishName: "Classic BBS Style", brand: "kuCar", category: .vintage, finish: .gold, assetName: "wheel_classic_bbs", thumbnailName: "thumb_wheel_classic_bbs"),

        // OEM
        WheelStyle(name: "OEM经典", englishName: "OEM Classic", brand: "kuCar", category: .oem, finish: .silver, assetName: "wheel_oem_classic", thumbnailName: "thumb_wheel_oem_classic"),
        WheelStyle(name: "OEM运动", englishName: "OEM Sport", brand: "kuCar", category: .oem, finish: .gunmetal, assetName: "wheel_oem_sport", thumbnailName: "thumb_wheel_oem_sport"),

        // Racing
        WheelStyle(name: "赛用轻量", englishName: "Race Lightweight", brand: "kuCar", category: .racing, finish: .black, assetName: "wheel_race_light", thumbnailName: "thumb_wheel_race_light"),
        WheelStyle(name: "竞技金", englishName: "Competition Gold", brand: "kuCar", category: .racing, finish: .gold, assetName: "wheel_comp_gold", thumbnailName: "thumb_wheel_comp_gold"),
    ]
}
