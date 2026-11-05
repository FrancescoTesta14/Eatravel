import SwiftUI

/// Shared by category results and Sort. Measurements follow the 760 × 350 reference.
struct DishCard: View {
    let dish: Dish
    var isWinner = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationLink(value: AppRoute.dish(id: dish.id)) {
            if typeSize.isAccessibilitySize {
                accessibleCard
            } else {
                referenceCard
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dish.name), Calories \(dish.nutrition.calories) kcal, Protein \(dish.nutrition.protein) grams, Carbs \(dish.nutrition.carbs) grams, Fat \(dish.nutrition.fat) grams")
        .accessibilityAddTraits(isWinner ? .isSelected : [])
        .accessibilityHint("Opens ingredients, map and recipe")
    }

    private var referenceCard: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 760
            ZStack(alignment: .topLeading) {
                cardBackground(radius: 52 * scale)
                    .padding(.top, 5 * scale)
                FoodPhoto(source: dish.image)
                    .frame(width: 325 * scale, height: 350 * scale)
                    .clipShape(RoundedRectangle(cornerRadius: 50 * scale))
                    .shadow(color: .black.opacity(0.12), radius: 6 * scale, y: 4 * scale)

                HStack(alignment: .top, spacing: 8 * scale) {
                    Text(dish.name)
                        .font(.system(size: 38 * scale, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 27 * scale, weight: .semibold))
                        .padding(.top, 7 * scale)
                }
                .frame(width: 385 * scale, height: 96 * scale, alignment: .topLeading)
                .offset(x: 350 * scale, y: 34 * scale)

                referenceNutrient("Calories", "~ \(dish.nutrition.calories) kcal", scale: scale)
                    .offset(x: 350 * scale, y: 150 * scale)
                referenceNutrient("Protein", "~ \(dish.nutrition.protein) g", scale: scale)
                    .offset(x: 575 * scale, y: 150 * scale)
                referenceNutrient("Carbs", "~ \(dish.nutrition.carbs) g", scale: scale)
                    .offset(x: 350 * scale, y: 250 * scale)
                referenceNutrient("Fat", "~ \(dish.nutrition.fat) g", scale: scale)
                    .offset(x: 575 * scale, y: 250 * scale)
            }
            .foregroundStyle(.black)
        }
        .aspectRatio(760.0 / 350.0, contentMode: .fit)
    }

    private func referenceNutrient(_ title: String, _ value: String, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5 * scale) {
            Text(title).font(.system(size: 34 * scale, weight: .bold))
            Text(value).font(.system(size: 26 * scale))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(width: 170 * scale, alignment: .leading)
    }

    private func cardBackground(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(isWinner ? EatravelStyle.selectedSurface : .white)
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(EatravelStyle.accent, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
    }

    // Large accessibility text stays complete instead of shrinking to fit the reference.
    private var accessibleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            FoodPhoto(source: dish.image)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            VStack(alignment: .leading, spacing: 12) {
                Label(dish.name, systemImage: "chevron.right").font(.headline)
                Text("Calories: ~ \(dish.nutrition.calories) kcal")
                Text("Protein: ~ \(dish.nutrition.protein) g")
                Text("Carbs: ~ \(dish.nutrition.carbs) g")
                Text("Fat: ~ \(dish.nutrition.fat) g")
            }.padding(16)
        }
        .foregroundStyle(.black)
        .background { cardBackground(radius: 24) }
    }
}
