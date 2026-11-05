import SwiftUI
import UIKit

/// Shares requests between carousel copies and keeps downloaded photos for reuse.
@MainActor
final class PhotoStore {
    static let shared = PhotoStore()
    private let images = NSCache<NSString, UIImage>()
    private var pending: [String: Task<UIImage, Error>] = [:]
    private let session: URLSession

    private init() {
        images.totalCostLimit = 64 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 16 * 1024 * 1024,
                                           diskCapacity: 128 * 1024 * 1024,
                                           diskPath: "EatravelPhotos")
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        session = URLSession(configuration: configuration)
    }

    func cached(_ source: String) -> UIImage? { images.object(forKey: source as NSString) }

    func image(for source: String) async throws -> UIImage {
        if let image = cached(source) { return image }
        if let task = pending[source] { return try await task.value }
        guard let url = URL(string: source), url.scheme == "https" else {
            throw URLError(.badURL)
        }
        let task = Task<UIImage, Error> {
            let (data, response) = try await session.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            images.setObject(image, forKey: source as NSString,
                             cost: Int(image.size.width * image.size.height * image.scale * image.scale * 4))
            return image
        }
        pending[source] = task
        defer { pending[source] = nil }
        return try await task.value
    }
}

private struct PhotoState {
    var image: UIImage?
    var source = ""
    var failed = false
}

struct FoodPhoto: View {
    let source: String
    // Retained for existing call sites; loading never displays a large symbol.
    var symbol = "fork.knife"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var storage = State(initialValue: PhotoState())
    private var state: PhotoState {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if state.source == source, let image = state.image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .transition(.opacity)
                } else {
                    PhotoSkeleton(animated: !reduceMotion && !state.failed)
                    if state.failed && state.source == source {
                        Text("Photo unavailable")
                            .font(.caption).foregroundStyle(.black.opacity(0.65))
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
        .task(id: source) { await load() }
    }

    @MainActor
    private func load() async {
        state = PhotoState(image: PhotoStore.shared.cached(source), source: source)
        guard state.image == nil else { return }
        do {
            let image = try await PhotoStore.shared.image(for: source)
            try Task.checkCancellation()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                state.image = image
            }
        } catch {
            guard !Task.isCancelled else { return }
            state.failed = true
        }
    }
}

private struct PhotoSkeleton: View {
    let animated: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [EatravelStyle.surface.opacity(0.8), EatravelStyle.background],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                        let progress = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
                        LinearGradient(colors: [.clear, .white.opacity(0.07), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: geometry.size.width * 0.8)
                            .offset(x: geometry.size.width * (progress * 3 - 1.5))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
}
