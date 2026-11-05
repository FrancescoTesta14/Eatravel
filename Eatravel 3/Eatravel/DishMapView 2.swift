import SwiftUI
import MapKit

struct DishMapView: View {
    let dish: Dish

    var body: some View {
        if let city = SampleData.cities.first(where: { $0.id == dish.cityID }),
           let coordinate = Self.cityCoordinates[city.id] {
            CityDishMapView(dish: dish, city: city, coordinate: coordinate)
                .id(dish.id)
        } else {
            Text("Map unavailable for this city.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private static let cityCoordinates: [String: CLLocationCoordinate2D] = [
        "napoli": .init(latitude: 40.8518, longitude: 14.2681),
        "london": .init(latitude: 51.5074, longitude: -0.1278),
        "paris": .init(latitude: 48.8566, longitude: 2.3522),
        "madrid": .init(latitude: 40.4168, longitude: -3.7038),
        "vienna": .init(latitude: 48.2082, longitude: 16.3738)
    ]
}

private struct FoodPlace: Identifiable {
    let id = UUID()
    let item: MKMapItem
}

private struct FoodMapState {
    var places: [FoodPlace] = []
    var loading = true
    var failed = false
    var nearby = false
    var request: MKLocalSearch?
    var retry = 0
}

private struct CityDishMapView: View {
    let dish: Dish
    let city: City
    let coordinate: CLLocationCoordinate2D
    private var storage = State(initialValue: FoodMapState())
    private var camera: State<MapCameraPosition>
    private var state: FoodMapState {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }

    init(dish: Dish, city: City, coordinate: CLLocationCoordinate2D) {
        self.dish = dish
        self.city = city
        self.coordinate = coordinate
        self.camera = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading("Best spots to try it")


            Map(position: camera.projectedValue) {
                if state.places.isEmpty {
                    Annotation("Search area · \(city.name)", coordinate: coordinate, anchor: .bottom) {
                        if let url = mapsSearchURL {
                            Link(destination: url) { EatravelMapPin() }
                                .accessibilityLabel("Search area in \(city.name). Search for \(dish.name) in Apple Maps")
                        }
                    }
                }
                ForEach(state.places) { place in
                    Annotation((state.nearby ? "Nearby · " : "") + (place.item.name ?? "Place"),
                               coordinate: place.item.placemark.coordinate, anchor: .bottom) {
                        Button { open(place.item) } label: { EatravelMapPin() }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open \(place.item.name ?? "place") in Apple Maps")
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls { MapCompass() }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topLeading) {
                if state.loading {
                    ProgressView("Finding places…")
                        .font(.caption).padding(12)
                        .background(.regularMaterial, in: Capsule())
                        .padding(10)
                }
            }

            if let url = mapsSearchURL {
                Link(destination: url) {
                    Label("Search in Apple Maps", systemImage: "map.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(EatravelStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

        }
        .task(id: state.retry) { await findPlaces() }
        .onDisappear { state.request?.cancel() }
    }

    private var mapsSearchURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "\(dish.name) \(city.name)"),
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)")
        ]
        return components?.url
    }

    private func open(_ item: MKMapItem) {
        // Opens the actual search result, not an invented address or restaurant.
        item.openInMaps(launchOptions: nil)
    }

    @MainActor
    private func findPlaces() async {
        state.request?.cancel()
        state.loading = true
        state.failed = false
        defer { state.loading = false; state.request = nil }
        let kind = dish.category == .sweets ? "bakeries pastry shops" : "restaurants"
        let queries = ["\(dish.name) \(city.name)", "\(kind) \(city.name)"]

        // Restore successful results before the first network request, including offline use.
        for (index, query) in queries.enumerated() {
            let cached = FoodPlaceCache.load(query)
            if !cached.isEmpty {
                state.places = cached.map { FoodPlace(item: $0) }
                state.nearby = index > 0
                camera.wrappedValue = .automatic
                break
            }
        }
        for (index, query) in queries.enumerated() {
            do {
                let matches = try await search(query)
                try Task.checkCancellation()
                guard !matches.isEmpty else { continue }
                let results = Array(matches.prefix(5))
                FoodPlaceCache.save(results, for: query)
                state.places = results.map { FoodPlace(item: $0) }
                state.nearby = index > 0
                camera.wrappedValue = .automatic
                return
            } catch {
                guard !Task.isCancelled else { return }
                // A failed dish lookup must not prevent the broader city search.
                state.failed = true
            }
        }
        // With no real results, the labelled city/search pin remains visible.
    }

    @MainActor
    private func search(_ query: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: 20000,
                                            longitudinalMeters: 20000)
        request.resultTypes = .pointOfInterest
        let search = MKLocalSearch(request: request)
        state.request = search
        let response = try await search.start()
        try Task.checkCancellation()
        let cityLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return response.mapItems.filter { item in
            guard let location = item.placemark.location else { return false }
            // A search region is only a hint; exclude results outside the city area.
            return cityLocation.distance(from: location) <= 20000
        }
    }
}

/// Uses the supplied JPEG unchanged, with a view crop and pin-shaped mask.
private struct EatravelMapPin: View {
    var body: some View {
        Image("MapPin")
            .resizable()
            .frame(width: 1600 * 0.072, height: 1600 * 0.072)
            .offset(x: -494 * 0.072, y: -365 * 0.072)
            .frame(width: 612 * 0.072, height: 872 * 0.072, alignment: .topLeading)
            .clipShape(MapPinOutline())
            .overlay(MapPinOutline().stroke(EatravelStyle.accent.opacity(0.5), lineWidth: 0.7))
            .shadow(color: .black.opacity(0.18), radius: 2, y: 2)
            .accessibilityHidden(true)
    }
}

private struct MapPinOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: point(0.5, 0))
        path.addCurve(to: point(1, 0.35), control1: point(0.79, 0), control2: point(1, 0.14))
        path.addCurve(to: point(0.5, 1), control1: point(1, 0.61), control2: point(0.64, 0.91))
        path.addCurve(to: point(0, 0.35), control1: point(0.36, 0.91), control2: point(0, 0.61))
        path.addCurve(to: point(0.5, 0), control1: point(0, 0.14), control2: point(0.21, 0))
        path.closeSubpath()
        return path
    }
}

private enum FoodPlaceCache {
    private struct Entry: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let savedAt: Date
    }
    private static func key(_ query: String) -> String { "Eatravel.map.v1." + query.lowercased() }
    static func load(_ query: String) -> [MKMapItem] {
        guard let data = UserDefaults.standard.data(forKey: key(query)),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries.filter { Date().timeIntervalSince($0.savedAt) < 7 * 86400 }.map { entry in
            let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: entry.latitude, longitude: entry.longitude)))
            item.name = entry.name
            return item
        }
    }
    static func save(_ items: [MKMapItem], for query: String) {
        let entries = items.map { item in
            Entry(name: item.name ?? "Place", latitude: item.placemark.coordinate.latitude,
                  longitude: item.placemark.coordinate.longitude, savedAt: Date())
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key(query))
        }
    }
}
