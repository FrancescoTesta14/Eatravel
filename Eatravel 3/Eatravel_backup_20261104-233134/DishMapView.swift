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
            Text("Where to try it").font(.title2.bold())
            Label(city.name, systemImage: "mappin.and.ellipse")
                .font(.subheadline).foregroundStyle(EatravelStyle.accent)

            Map(position: camera.projectedValue) {
                ForEach(state.places) { place in
                    Annotation(place.item.name ?? "Place", coordinate: place.item.placemark.coordinate) {
                        Button { open(place.item) } label: {
                            Image(systemName: dish.category == .specialties ? "basket.fill" : "fork.knife")
                                .font(.subheadline.bold())
                                .foregroundStyle(EatravelStyle.background)
                                .padding(10)
                                .background(EatravelStyle.accent, in: Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                        .accessibilityLabel("Open \(place.item.name ?? "place") in Apple Maps")
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls { MapCompass() }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topLeading) {
                if state.loading {
                    ProgressView("Finding places…")
                        .font(.caption).padding(12)
                        .background(.regularMaterial, in: Capsule())
                        .padding(10)
                }
            }

            if state.failed {
                Text("Places could not be loaded. Check your connection and try again.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Try again") { state.retry += 1 }
                    .foregroundStyle(EatravelStyle.accent)
            } else if !state.loading && state.places.isEmpty {
                Text("No matching places found here. Try searching in Apple Maps.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else if !state.places.isEmpty {
                ForEach(state.places) { place in
                    Button { open(place.item) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(EatravelStyle.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.item.name ?? "Place").font(.subheadline.bold())
                                if let address = place.item.placemark.title {
                                    Text(address).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption.bold())
                        }.padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(EatravelStyle.surface, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
            }

            if let url = mapsSearchURL {
                Link(destination: url) {
                    Label("Search in Apple Maps", systemImage: "map.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(EatravelStyle.background)
                        .frame(maxWidth: .infinity).padding(15)
                        .background(EatravelStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                }
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
        state.places = []
        defer { state.loading = false; state.request = nil }
        do {
            var matches = try await search("\(dish.name) \(city.name)")
            try Task.checkCancellation()
            if matches.isEmpty {
                let kind = dish.category == .specialties ? "delicatessen food shops" : "restaurants"
                matches = try await search("\(kind) \(city.name)")
                try Task.checkCancellation()
            }
            state.places = matches.prefix(5).map { FoodPlace(item: $0) }
            if !state.places.isEmpty { camera.wrappedValue = .automatic }
        } catch {
            guard !Task.isCancelled else { return }
            state.failed = true
        }
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
