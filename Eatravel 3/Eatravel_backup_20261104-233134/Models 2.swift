import Foundation

struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let country: String
    let subtitle: String
    let image: String
    var recipeCount: Int { dishes.count }
    var specialtyCount: Int { dishes.filter { $0.category == .specialties }.count }
    var dishes: [Dish] { SampleData.dishes.filter { $0.cityID == id } }
}

enum FoodCategory: String, CaseIterable, Identifiable {
    case streetFood, mains, sweets, specialties
    var id: String { rawValue }
    func title(in cityID: String) -> String {
        switch self {
        case .streetFood: "Street Food & Snacking"
        case .mains: "Main Dishes"
        case .sweets: "Baked Goods & Sweets"
        case .specialties: "Local Specialties"
        }
    }
    var symbol: String {
        switch self {
        case .streetFood: "takeoutbag.and.cup.and.straw.fill"
        case .mains: "fork.knife"
        case .sweets: "birthday.cake.fill"
        case .specialties: "sparkles"
        }
    }
}

struct Nutrition: Hashable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Double
    let sugar: Double
    let sodium: Int
    var items: [(name: String, value: String, symbol: String)] {
        [("Calories", "\(calories) kcal", "flame"),
         ("Protein", "\(protein) g", "bolt"),
         ("Carbs", "\(carbs) g", "leaf"),
         ("Fat", "\(fat) g", "drop"),
         ("Fiber", fiber.formatted(.number.locale(Locale(identifier: "en_GB"))) + " g", "leaf.circle"),
         ("Sugar", sugar.formatted(.number.locale(Locale(identifier: "en_GB"))) + " g", "cube"),
         ("Sodium", "\(sodium) mg", "waterbottle")]
    }
}

struct Dish: Identifiable, Hashable {
    let id: String
    let cityID: String
    let category: FoodCategory
    let name: String
    let description: String
    let image: String
    let minutes: Int
    let ingredients: [String]
    let steps: [String]
    let nutrition: Nutrition
}

/// Stable, complete navigation identity; no destination depends on a visible carousel copy.
enum AppRoute: Hashable {
    case categories(cityID: String)
    case dishes(cityID: String, category: FoodCategory)
    case dish(id: String)
    case sort(cityID: String)
}

extension Dish {
    var durationText: String { Self.formatDuration(minutes: minutes) }

    static func formatDuration(minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? "\(hours) h" : "\(hours) h \(remaining) min"
    }
}
