import SwiftUI

private struct RecipeProgress {
    var ingredients: Set<Int> = []
    var steps: Set<Int> = []
    var showingGuide = false
}

struct RecipeSectionView: View {
    let dish: Dish
    private var storage = State(initialValue: RecipeProgress())
    private var progress: RecipeProgress {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }
    private var completed: Binding<Set<Int>> {
        Binding(get: { progress.steps }, set: { progress.steps = $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(dish.category == .specialties ? "Serving ingredients" : "Ingredients")
                        .font(.title2.bold())
                    Spacer()
                    Text("\(progress.ingredients.count)/\(dish.ingredients.count)")
                        .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                }
                ForEach(Array(dish.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    Button {
                        if !progress.ingredients.insert(index).inserted { progress.ingredients.remove(index) }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: progress.ingredients.contains(index) ? "checkmark.circle.fill" : "circle")
                                .font(.title3).foregroundStyle(EatravelStyle.accent)
                            Text(ingredient)
                                .strikethrough(progress.ingredients.contains(index))
                                .foregroundStyle(progress.ingredients.contains(index) ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(.vertical, 8).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(progress.ingredients.contains(index) ? "Ready" : "Not checked")
                    Divider()
                }
            }

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(dish.category == .specialties ? "Serving suggestion" : "Recipe").font(.title2.bold())
                    Spacer()
                    if !progress.steps.isEmpty || !progress.ingredients.isEmpty {
                        Button("Reset") { progress = RecipeProgress() }
                            .font(.subheadline).foregroundStyle(EatravelStyle.accent)
                    }
                }
                HStack(spacing: 18) {
                    Label("\(dish.minutes) min", systemImage: "clock")
                    Label("\(dish.steps.count) steps", systemImage: "list.number")
                }.font(.subheadline).foregroundStyle(.secondary)

                if !dish.steps.isEmpty {
                    ProgressView(value: Double(progress.steps.count), total: Double(dish.steps.count))
                        .tint(EatravelStyle.accent)
                    Text(progress.steps.count == dish.steps.count ? "All done. Enjoy!" : "\(progress.steps.count) of \(dish.steps.count) steps completed")
                        .font(.caption).foregroundStyle(.secondary)
                    Button { progress.showingGuide = true } label: {
                        Label(progress.steps.isEmpty ? "Start cooking" : "Open cooking guide", systemImage: "play.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                            .foregroundStyle(EatravelStyle.background)
                            .background(EatravelStyle.accent, in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                ForEach(Array(dish.steps.enumerated()), id: \.offset) { index, step in
                    Button {
                        if !progress.steps.insert(index).inserted { progress.steps.remove(index) }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle().fill(progress.steps.contains(index) ? EatravelStyle.accent : EatravelStyle.accent)
                                if progress.steps.contains(index) {
                                    Image(systemName: "checkmark").font(.subheadline.bold())
                                } else {
                                    Text(String(format: "%02d", index + 1)).font(.subheadline.bold())
                                }
                            }.foregroundStyle(EatravelStyle.background).frame(width: 36, height: 36)
                            Text(step).lineSpacing(4).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(EatravelStyle.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step \(index + 1). \(step)")
                    .accessibilityValue(progress.steps.contains(index) ? "Completed" : "Not completed")
                    .accessibilityHint("Double tap to change completion")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Good to know", systemImage: "lightbulb").font(.subheadline.bold())
                    Text(dish.cookingTip).font(.subheadline).foregroundStyle(.secondary)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(EatravelStyle.surface.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .sheet(isPresented: Binding(get: { progress.showingGuide }, set: { progress.showingGuide = $0 })) {
            CookingGuideView(dish: dish, completed: completed)
        }
    }
}

private struct CookingGuideView: View {
    let dish: Dish
    @Binding var completed: Set<Int>
    @Environment(\.dismiss) private var dismiss
    private var position = State(initialValue: 0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(dish.name).font(.title.bold())
                    Text("Step \(position.wrappedValue + 1) of \(dish.steps.count)")
                        .font(.headline).foregroundStyle(EatravelStyle.accent)
                    if dish.steps.indices.contains(position.wrappedValue) {
                        Text(dish.steps[position.wrappedValue]).font(.title2).lineSpacing(8)
                    }
                    ProgressView(value: Double(completed.count), total: Double(max(1, dish.steps.count)))
                        .tint(EatravelStyle.accent)
                    DisclosureGroup("Ingredients") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(dish.ingredients, id: \.self) { Text($0) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                    }
                    HStack {
                        Button("Previous") { position.wrappedValue -= 1 }
                            .disabled(position.wrappedValue == 0)
                        Spacer()
                        Button(position.wrappedValue == dish.steps.count - 1 ? "Done" : "Done & next") {
                            completed.insert(position.wrappedValue)
                            if position.wrappedValue < dish.steps.count - 1 {
                                position.wrappedValue += 1
                            } else { dismiss() }
                        }.buttonStyle(.borderedProminent).tint(EatravelStyle.accent)
                            .foregroundStyle(EatravelStyle.background)
                    }
                }.padding(24)
            }
            .background(EatravelStyle.background.ignoresSafeArea())
            .navigationTitle("Cooking guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
        }
        .preferredColorScheme(.light)
        .presentationDragIndicator(.visible)
        .onAppear { position.wrappedValue = dish.steps.indices.first(where: { !completed.contains($0) }) ?? 0 }
    }
}

extension Dish {
    var cookingTip: String {
        switch category {
        case .streetFood: "Prepare the filling and accompaniments before cooking. For fried recipes, work in small batches and drain before serving so the coating stays crisp."
        case .mains: "Read all the steps and prepare your ingredients first. Cooking times are approximate: check texture and doneness before serving."
        case .sweets: "Measure ingredients before starting and preheat the oven when the recipe calls for baking. Allow any cooling, resting or proving time mentioned in the steps."
        case .specialties: "This is a serving idea for a ready-made local product. Follow its label for storage, ingredients and allergens, and prepare accompaniments just before serving."
        }
    }
}
