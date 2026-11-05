import SwiftUI

private struct CarouselState {
    var index = SampleData.cities.firstIndex(where: { $0.id == "napoli" }) ?? 0
    var offset: CGFloat = 0
    var animating = false
}

struct CitySelectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var storage = State(initialValue: CarouselState())
    private var state: CarouselState {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }
    private let cities = SampleData.cities
    private var path = State(initialValue: [AppRoute]())

    var body: some View {
        NavigationStack(path: path.projectedValue) {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 28) {
                        HomeTitle()
                            .padding(.horizontal, 24)
                            .padding(.top, 72)
                            .padding(.bottom, 36)

                        VStack(spacing: 22) {
                            carousel(width: geometry.size.width, photoHeight: min(geometry.size.height * 0.40, 340))


                        }
                        Spacer(minLength: 30)
                    }
                    .frame(minHeight: geometry.size.height, alignment: .center)
                    .padding(.bottom, 24)
                }
            }
            .background(EatravelStyle.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
            .task {
                await withTaskGroup(of: Void.self) { group in
                    for city in cities {
                        group.addTask { _ = try? await PhotoStore.shared.image(for: city.image) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .categories(let cityID):
            if let city = cities.first(where: { $0.id == cityID }) {
                CategoryListView(city: city).id(route)
            }
        case .dishes(let cityID, let category):
            if let city = cities.first(where: { $0.id == cityID }) {
                DishListView(city: city, category: category).id(route)
            }
        case .dish(let id):
            if let dish = SampleData.dishes.first(where: { $0.id == id }) {
                DishDetailView(dish: dish).id(route)
            }
        case .sort(let cityID):
            if let city = cities.first(where: { $0.id == cityID }) {
                SortView(city: city).id(route)
            }
        }
    }

    private func wrapped(_ index: Int) -> Int {
        (index % cities.count + cities.count) % cities.count
    }

    private func carousel(width: CGFloat, photoHeight: CGFloat) -> some View {
        let cardWidth = width * 0.70
        let stride = cardWidth + 18
        return ZStack {
            // Neighbouring cards wrap around the data, so neither end is ever empty.
            ForEach(-3...3, id: \.self) { relative in
                let city = cities[wrapped(state.index + relative)]
                let position = CGFloat(relative) * stride + state.offset
                let distance = min(abs(position) / stride, 1)
                NavigationLink(value: AppRoute.categories(cityID: city.id)) {
                    VStack(spacing: 0) {
                        FoodPhoto(source: city.image, symbol: "building.2.crop.circle")
                            .frame(height: photoHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                        VStack(spacing: 5) {
                            Text("\(city.name), \(city.country)").font(.title2.bold())
                            Text("\(city.recipeCount) recipes").font(.subheadline)
                        }
                        .foregroundStyle(.black).padding(.vertical, 22)
                        .frame(maxWidth: .infinity)
                    }
                    .background(.white, in: RoundedRectangle(cornerRadius: 26))
                    .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(EatravelStyle.accent, lineWidth: 2))
                    .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                    .contentShape(RoundedRectangle(cornerRadius: 26))
                }
                .buttonStyle(.plain)
                .frame(width: cardWidth)
                .scaleEffect(reduceMotion ? 1 : 1 - distance * 0.12)
                .opacity(1 - distance * 0.50)
                .offset(x: position)
                .disabled(state.animating)
                .accessibilityHidden(relative != 0)
                .accessibilityLabel("\(city.name), \(city.country), \(city.recipeCount) recipes")
                .accessibilityHint("Opens food categories")
            }
        }
        .frame(width: width)
        .clipped()
        .contentShape(Rectangle())
        // Once a drag is recognised, it takes precedence over the card link.
        // A stationary tap still reaches NavigationLink normally.
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard !state.animating,
                          abs(value.translation.width) > abs(value.translation.height) else { return }
                    state.offset = max(-stride, min(stride, value.translation.width))
                }
                .onEnded { value in
                    guard !state.animating else { return }
                    let horizontal = abs(value.translation.width) > abs(value.translation.height)
                    let predicted = value.predictedEndTranslation.width
                    let step = horizontal && (abs(value.translation.width) > stride * 0.20 || abs(predicted) > stride * 0.35)
                        ? (value.translation.width < 0 ? 1 : -1) : 0
                    move(by: step, stride: stride)
                }
        )
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1, stride: stride)
            case .decrement: move(by: -1, stride: stride)
            @unknown default: break
            }
        }
    }

    private func move(by steps: Int, stride: CGFloat) {
        guard !state.animating else { return }
        state.animating = true
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.30), completionCriteria: .removed) {
            state.offset = -CGFloat(steps) * stride
        } completion: {
            // Rebase only after the slide ends. Equivalent neighbouring cards stay in place.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                state.index = wrapped(state.index + steps)
                state.offset = 0
                state.animating = false
            }
        }
    }
}

struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View { CitySelectionView().preferredColorScheme(.light) }
}

private struct HomeTitle: View {
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize: CGFloat = 38

    var body: some View {
        Text("Where we are today")
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isHeader)
    }
}
