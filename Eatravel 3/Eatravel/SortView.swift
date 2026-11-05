import SwiftUI

private struct SortState {
    var rotation: Double = 0
    var selectedID: String?
    var spinning = false
    var request = 0
    var candidates: [Dish]
}

struct SortView: View {
    let city: City
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var storage: State<SortState>
    private var state: SortState {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }
    init(city: City) {
        self.city = city
        storage = State(initialValue: SortState(candidates: WheelSelection.candidates(in: city)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Sort your next dish")
                    .font(.largeTitle.bold()).foregroundStyle(.black)
                wheel
                    .frame(maxWidth: 460)
                    .padding(.horizontal, -12)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                Button {
                    guard !state.spinning, !state.candidates.isEmpty else { return }
                    state.selectedID = nil
                    state.spinning = true
                    state.request += 1
                } label: {
                    Text("Spin")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 240, height: 58)
                        .background(EatravelStyle.accent, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.18), radius: 5, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(state.spinning || state.candidates.isEmpty)
                .accessibilityValue(state.spinning ? "Spinning" : "Ready")
                .frame(maxWidth: .infinity)

                Button {
                    guard !state.spinning else { return }
                    state = SortState(candidates: WheelSelection.candidates(in: city))
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(EatravelStyle.accent)
                        .frame(width: 48, height: 48)
                        .background(EatravelStyle.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(state.spinning)
                .accessibilityLabel("Refresh dishes")
                .accessibilityHint("Choose two new candidates from each category in \(city.name)")
                .frame(maxWidth: .infinity)

                if state.candidates.isEmpty {
                    Text("Add at least two dishes to each category to use the wheel.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sorted dish")
                        .font(.title2.bold()).foregroundStyle(.black)
                        .padding(.top, 20)
                    LazyVStack(spacing: 12) {
                        ForEach(WheelSelection.displayOrder(state.candidates, winnerID: state.selectedID)) { dish in
                            DishCard(dish: dish, isWinner: state.selectedID == dish.id)
                                .disabled(state.spinning)
                        }
                    }
                    .padding(.horizontal, -8)
                }
            }.padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .eatravelScreen()
        .task(id: state.request) {
            // Initial appearance and return from a card must never trigger a spin.
            guard state.request > 0, state.spinning else { return }
            await spin()
        }
        .onDisappear { state.spinning = false }
    }

    private var wheel: some View {
        GeometryReader { geometry in
            let size = geometry.size.width - 20
            let count = max(state.candidates.count, 1)
            let step = 360.0 / Double(count)
            ZStack {
                ZStack {
                    ForEach(Array(state.candidates.enumerated()), id: \.element.id) { index, dish in
                        let angle = Double(index) * step
                        WheelSector(start: angle - step / 2, end: angle + step / 2)
                            .fill(index.isMultiple(of: 2) ? EatravelStyle.surface : .white)
                            .overlay(WheelSector(start: angle - step / 2, end: angle + step / 2)
                                .stroke(EatravelStyle.accent.opacity(0.6), lineWidth: 1))
                        Text(dish.name)
                            .font(.system(size: min(17, max(14, size * 0.048)), weight: .bold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.8)
                            .frame(width: size * 0.28, height: size * 0.16)
                            .rotationEffect(.degrees(angle > 90 && angle < 270 ? angle + 180 : angle))
                            .position(x: size / 2 + cos(angle * .pi / 180) * size * 0.34,
                                      y: size / 2 + sin(angle * .pi / 180) * size * 0.34)
                    }
                    Circle().strokeBorder(EatravelStyle.accent, lineWidth: 2)
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(state.rotation))

                // BrandMark and the installed AppIcon use the exact same source artwork.
                Image("BrandMark")
                    .resizable().scaledToFit()
                    .frame(width: size * 0.19, height: size * 0.19)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.045))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.045).stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.12), radius: 3)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(alignment: .trailing) {
                Image(systemName: "arrowtriangle.left.fill")
                    .font(.system(size: 32)).foregroundStyle(EatravelStyle.accent)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 3)
            }
        }.aspectRatio(1, contentMode: .fit)
    }

    @MainActor
    private func spin() async {
        guard let index = state.candidates.indices.randomElement() else { state.spinning = false; return }
        let winnerID = state.candidates[index].id
        let target = WheelSelection.targetRotation(current: state.rotation, winner: index,
                                                    count: state.candidates.count, fullTurns: reduceMotion ? 0 : 4)
        withAnimation(reduceMotion ? nil : .easeOut(duration: 2.8)) { state.rotation = target }
        if !reduceMotion {
            do { try await Task.sleep(for: .milliseconds(2800)) }
            catch { state.spinning = false; return }
        }
        guard !Task.isCancelled else { state.spinning = false; return }
        state.selectedID = winnerID
        state.spinning = false
    }
}

private struct WheelSector: Shape {
    let start: Double
    let end: Double
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        path.closeSubpath()
        return path
    }
}
