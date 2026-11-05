import SwiftUI

struct CategoryListView: View {
    let city: City
    private let categories: [FoodCategory] = [.specialties, .mains, .streetFood, .sweets]
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeading(title: "Food Categories").padding(.bottom, 6)
                ForEach(categories) { category in
                    let dishes = city.dishes.filter { $0.category == category }
                    NavigationLink(value: AppRoute.dishes(cityID: city.id, category: category)) {
                        VStack(spacing: 0) {
                            FoodPhoto(source: dishes.first?.image ?? "", symbol: category.symbol)
                                .frame(height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .contentShape(Rectangle())
                            HStack {
                                Text(category.title(in: city.id)).font(.title3.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                            }.foregroundStyle(.black).padding(18)
                        }
                        .background(.white, in: RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(EatravelStyle.accent, lineWidth: 1.5).allowsHitTesting(false))
                        .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                        .contentShape(RoundedRectangle(cornerRadius: 24))
                    }.buttonStyle(.plain)
                }
            }.padding(24).padding(.bottom, 70)
        }
        .overlay(alignment: .bottomTrailing) { SortIcon(city: city).padding(24) }
        .navigationBarTitleDisplayMode(.inline)
        .eatravelScreen()
    }
}

struct DishListView: View {
    let city: City
    let category: FoodCategory
    private var dishes: [Dish] { city.dishes.filter { $0.category == category } }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ScreenHeading(title: category.title(in: city.id))
                ForEach(dishes) { DishCard(dish: $0) }
            }.padding(.horizontal, 16).padding(.vertical, 24)
        }.navigationBarTitleDisplayMode(.inline).eatravelScreen()
    }
}
