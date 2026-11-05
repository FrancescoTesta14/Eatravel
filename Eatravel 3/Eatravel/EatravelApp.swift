import SwiftUI

@main
struct EatravelApp: App {
    var body: some Scene {
        WindowGroup {
            CitySelectionView()
                .preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "en"))
                .tint(EatravelStyle.accent)
        }
    }
}
