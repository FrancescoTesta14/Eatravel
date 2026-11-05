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
                        Text(dish.description).foregroundStyle(.black.opacity(0.8))
                        HStack(spacing: 22) {
                            Label("\(dish.minutes) min", systemImage: "clock")
                            Label("1 serving", systemImage: "person")
                        }.font(.subheadline).foregroundStyle(EatravelStyle.accent)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Nutritional values").font(.title2.bold())
                        Label("Unverified demo estimates for the serving below", systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.black.opacity(0.7))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                            ForEach(dish.nutrition.items, id: \.name) { item in
                                VStack(spacing: 10) {
                                    Image(systemName: item.symbol).font(.title2)
                                    Text(item.name).font(.caption)
                                    Text("≈ " + item.value).font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(EatravelStyle.accent, lineWidth: 1))
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    DishMapView(dish: dish)
                    RecipeSectionView(dish: dish)
                        .id(dish.id)
                    Text("Simplified prototype preparations and illustrative images. Nutrition is unverified demonstration data for the whole suggested serving, including accompaniments. For packaged products, check the label for ingredients and allergens.")
                        .font(.caption).foregroundStyle(.black.opacity(0.55))
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
