import SwiftUI

struct RecipeSectionView: View {
    let dish: Dish
    private var showingRecipe = State(initialValue: false)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeading("Recipe")
            Button { showingRecipe.wrappedValue = true } label: {
                VStack(alignment: .leading, spacing: 0) {
                    FoodPhoto(source: dish.image)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(dish.name).font(.headline)
                        Text("Ingredients: " + dish.ingredients.joined(separator: ", "))
                            .font(.caption).lineLimit(2)
                        HStack(spacing: 22) {
                            Label(dish.durationText, systemImage: "clock")
                            Label("1 serving", systemImage: "person")
                        }.font(.caption).padding(.top, 5)
                    }.padding(12)
                }
                .foregroundStyle(.black)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(EatravelStyle.accent, lineWidth: 2))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the recipe in a sheet")
        }
        .sheet(isPresented: showingRecipe.projectedValue) {
            RecipeSheet(dish: dish)
        }
    }
}

private struct RecipeSheet: View {
    let dish: Dish
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Ricetta \(dish.name)")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close recipe")
            }
            .padding(.leading, 24).padding(.trailing, 12).padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    FoodPhoto(source: dish.image, contentMode: .fit).frame(height: 280)
                    HStack(spacing: 0) {
                        metadata(dish.durationText, symbol: "timer")
                        Divider().frame(height: 44)
                        metadata("1 serving", symbol: "person")
                    }.padding(.horizontal, 48)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(dish.name).font(.largeTitle.bold()).foregroundStyle(.black)
                        SectionHeading("Ingredients")
                        ForEach(Array(dish.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            Text("• " + ingredient)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        SectionHeading("Steps").padding(.top, 12)
                        ForEach(Array(dish.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).").fontWeight(.semibold)
                                    .foregroundStyle(EatravelStyle.accent)
                                Text(step).lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }.padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
        }
        .foregroundStyle(.black)
        .background(.white)
        .presentationBackground(.white)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .preferredColorScheme(.light)
    }

    private func metadata(_ title: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3)
            Text(title).font(.subheadline)
        }.frame(maxWidth: .infinity)
    }
}
