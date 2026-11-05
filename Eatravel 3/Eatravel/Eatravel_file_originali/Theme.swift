import SwiftUI

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        precondition(clean.count == 6, "Expected a six-digit RGB hex colour")
        guard let value = UInt64(clean, radix: 16) else { preconditionFailure("Invalid hex colour") }
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255, opacity: 1)
    }
}

enum EatravelStyle {
    static let accent = Color(hex: "4A6B5D")
    static let background = Color(hex: "FAFAFA")
    static let surface = Color(hex: "EEF2EF")
    static let selectedSurface = Color(hex: "DCE7E1")
}

struct ScreenHeading: View {
    var eyebrow: String? = nil
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow { Text(eyebrow).font(.subheadline).foregroundStyle(EatravelStyle.accent) }
            Text(title).font(.largeTitle.bold()).foregroundStyle(.black)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SortIcon: View {
    let city: City
    var body: some View {
        NavigationLink(value: AppRoute.sort(cityID: city.id)) {
            Image(systemName: "dice")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(EatravelStyle.accent, in: Circle())
                .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
        }
        .accessibilityLabel("Sort")
        .accessibilityHint("Pick a random dish from \(city.name)")
    }
}

extension View {
    func eatravelScreen() -> some View {
        self.background(EatravelStyle.background.ignoresSafeArea())
            .foregroundStyle(.black)
            .toolbarBackground(EatravelStyle.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar(.visible, for: .navigationBar)
    }
}

/// Shared section typography, matching Nutritional values (Dynamic Type Title 2).
struct SectionHeading: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
