import SwiftUI

struct DishDetailView: View {
    let dish: Dish
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                FoodPhoto(source: dish.image)
                    .frame(height: 280)
                    .overlay(alignment: .bottomTrailing) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 6) { categoryTag; cityTag }
                            VStack(alignment: .trailing, spacing: 6) { categoryTag; cityTag }
                        }.padding(16)
                    }

                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(dish.name).font(.largeTitle.bold()).foregroundStyle(.black)
                        Text("Ingredients: " + dish.ingredients.joined(separator: ", "))
                            .font(.subheadline).foregroundStyle(.black)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading("Nutritional values")
                        Label("Indicative values for a person", systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.black)
                        NutritionTiles(nutrition: dish.nutrition)
                    }
                    DishMapView(dish: dish)
                    RecipeSectionView(dish: dish)
                        .id(dish.id)

                }.padding(.horizontal, 24).padding(.bottom, 36)
            }
        }.navigationBarTitleDisplayMode(.inline).eatravelScreen()
    }
    private var categoryTag: some View {
        tag(dish.category.title(in: dish.cityID))
    }
    private var cityTag: some View {
        tag(SampleData.cities.first(where: { $0.id == dish.cityID }).map { "\($0.name), \($0.country)" } ?? "")
    }
    private func tag(_ title: String) -> some View {
        Text(title).font(.caption2.weight(.medium)).foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(EatravelStyle.accent, in: RoundedRectangle(cornerRadius: 7))
    }

}

private struct NutritionTiles: View {
    let nutrition: Nutrition
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if typeSize.isAccessibilitySize {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
                ForEach(nutrition.items, id: \.name) { tile($0) }
            }
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(Array(nutrition.items.prefix(4)), id: \.name) { tile($0) }
                }
                HStack(spacing: 6) {
                    ForEach(Array(nutrition.items.suffix(3)), id: \.name) { tile($0) }
                }.padding(.horizontal, 40)
            }
        }
    }
    private func tile(_ item: (name: String, value: String, symbol: String)) -> some View {
        VStack(spacing: 9) {
            Image(systemName: item.symbol).font(.title3)
            Text(item.name).font(.caption).lineLimit(1).minimumScaleFactor(0.8)
            Text("≈ " + item.value).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).padding(.horizontal, 3)
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(EatravelStyle.accent, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
