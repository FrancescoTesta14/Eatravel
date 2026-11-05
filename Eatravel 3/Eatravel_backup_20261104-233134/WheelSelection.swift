import Foundation

enum WheelSelection {
    /// A complete round always contains exactly two distinct local dishes per category.
    static func candidates(in city: City) -> [Dish] {
        let groups = FoodCategory.allCases.map { category in
            city.dishes.filter { $0.category == category }
        }
        guard groups.allSatisfy({ $0.count >= 2 }) else { return [] }
        return groups.flatMap { Array($0.shuffled().prefix(2)) }.shuffled()
    }

    /// Reorder only the cards; sector indexes and the winning angle remain unchanged.
    static func displayOrder(_ candidates: [Dish], winnerID: String?) -> [Dish] {
        guard let winner = candidates.first(where: { $0.id == winnerID }) else { return candidates }
        return [winner] + candidates.filter { $0.id != winner.id }
    }

    /// The pointer is at the right-hand edge, at zero degrees.
    static func targetRotation(current: Double, winner: Int, count: Int, fullTurns: Int) -> Double {
        let destination = (360 - Double(winner) * 360 / Double(count)).truncatingRemainder(dividingBy: 360)
        let normalized = current.truncatingRemainder(dividingBy: 360)
        return current + Double(fullTurns) * 360 + (destination - normalized + 360).truncatingRemainder(dividingBy: 360)
    }
}
