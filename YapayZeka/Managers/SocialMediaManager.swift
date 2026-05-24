import Foundation
import Combine

@MainActor
final class SocialMediaManager: ObservableObject {
    static let shared = SocialMediaManager()

    @Published var connections: [SocialConnection] = []
    @Published var lastMessage: String?

    private let storageKey = "ekinciler.social.connections"

    private init() {
        load()
        if connections.isEmpty { seedPlatforms() }
    }

    func syncFromBackend() async {
        guard BackendConfig.useBackend else { return }
        do {
            connections = try await APIClient.shared.fetchSocialConnections()
            save()
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    func connect(platform: AIPlatform) {
        switch platform {
        case .instagram, .facebook:
            Task {
                if !BackendConfig.useBackend {
                    lastMessage = "Gerçek hesap için: Ayarlar → Backend açık + sunucu çalışıyor olmalı."
                    return
                }
                await MetaOAuthService.shared.startOAuth()
                await syncFromBackend()
            }
        default:
            guard let index = connections.firstIndex(where: { $0.platform == platform.rawValue }) else { return }
            connections[index].isConnected = true
            connections[index].username = "@\(platform.rawValue.lowercased())_ekinciler"
            connections[index].connectedAt = Date()
            save()
            lastMessage = "\(platform.rawValue) bağlantısı simüle edildi."
        }
    }

    func disconnect(platform: AIPlatform) {
        switch platform {
        case .instagram, .facebook:
            Task {
                if BackendConfig.useBackend {
                    try? await APIClient.shared.disconnectMeta()
                    await syncFromBackend()
                }
                for p in [AIPlatform.instagram, .facebook] {
                    if let i = connections.firstIndex(where: { $0.platform == p.rawValue }) {
                        connections[i].isConnected = false
                        connections[i].username = nil
                        connections[i].connectedAt = nil
                    }
                }
                save()
                lastMessage = "Facebook ve Instagram bağlantısı kaldırıldı."
            }
        default:
            guard let index = connections.firstIndex(where: { $0.platform == platform.rawValue }) else { return }
            connections[index].isConnected = false
            connections[index].username = nil
            connections[index].connectedAt = nil
            save()
            lastMessage = "\(platform.rawValue) bağlantısı kaldırıldı."
        }
    }

    func publish(platform: String, content: String, imageUrl: String?) async {
        guard BackendConfig.useBackend else {
            lastMessage = "\(platform) paylaşımı yerel olarak simüle edildi."
            return
        }
        do {
            let result = try await APIClient.shared.publishPost(platform: platform, content: content, imageUrl: imageUrl)
            lastMessage = result.simulated == true
                ? (result.message ?? "Paylaşım simüle edildi")
                : "Paylaşım başarılı! ID: \(result.postId ?? "-")"
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    var connectedCount: Int { connections.filter(\.isConnected).count }

    private func seedPlatforms() {
        connections = AIPlatform.allCases.map {
            SocialConnection(platform: $0.rawValue, isConnected: false, username: nil, connectedAt: nil)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SocialConnection].self, from: data) else { return }
        connections = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(connections) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
