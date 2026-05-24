import Foundation
import Combine

@MainActor
final class BrandManager: ObservableObject {
    static let shared = BrandManager()

    @Published var profile = BrandProfile()

    private let storageKey = "ekinciler.brand.profile"

    private init() { load() }

    func syncFromBackend() async {
        guard BackendConfig.useBackend else { return }
        do {
            profile = try await APIClient.shared.fetchBrand()
            persistLocally()
        } catch { /* yerel */ }
    }

    func save() async {
        if BackendConfig.useBackend {
            do {
                profile = try await APIClient.shared.saveBrand(profile)
            } catch { /* yerel kaydet */ }
        }
        persistLocally()
    }

    private func persistLocally() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(BrandProfile.self, from: data) else { return }
        profile = decoded
    }
}
