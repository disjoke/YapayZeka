import Foundation
import Combine

@MainActor
final class VideoService: ObservableObject {
    static let shared = VideoService()

    @Published var isLoading = false
    @Published var script = ""
    @Published var videoURL: URL?
    @Published var statusMessage = ""
    @Published var error: String?
    @Published var usedDirectOpenAI = false

    private init() {}

    func generateScript(topic: String, duration: String, style: String) async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else {
            error = "Lütfen video konusu girin."
            return
        }

        isLoading = true
        error = nil
        usedDirectOpenAI = false
        defer { isLoading = false }

        // Önce backend (açıksa), olmazsa doğrudan OpenAI
        if BackendConfig.useBackend {
            do {
                script = try await APIClient.shared.aiVideoScript(
                    topic: trimmedTopic, duration: duration, style: style
                )
                statusMessage = "Senaryo oluşturuldu (sunucu)"
                return
            } catch let backendError {
                if let fallback = await tryDirectScript(topic: trimmedTopic, duration: duration, style: style) {
                    script = fallback
                    statusMessage = "Sunucu kapalı — OpenAI ile oluşturuldu"
                    return
                }
                self.error = friendlyNetworkError(backendError)
                return
            }
        }

        do {
            script = try await AIService.shared.generateVideoScript(
                topic: trimmedTopic, duration: duration, style: style
            )
            statusMessage = "Senaryo oluşturuldu"
            usedDirectOpenAI = true
        } catch let err {
            self.error = friendlyNetworkError(err)
        }
    }

    func generateVideo(prompt: String) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Önce senaryo oluşturun veya konu girin."
            return
        }

        isLoading = true
        error = nil
        videoURL = nil
        defer { isLoading = false }

        if BackendConfig.useBackend {
            do {
                let result = try await APIClient.shared.aiVideoGenerate(prompt: trimmed)
                statusMessage = result.message ?? result.status ?? "Video işlendi"
                if let urlString = result.videoUrl, let url = URL(string: urlString) {
                    videoURL = url
                }
                return
            } catch let err {
                self.error = friendlyNetworkError(err) + (AppConfig.isAppStoreBuild
                    ? "\n\nVideo üretimi Ekinciler bulut sunucusu üzerinden yapılır."
                    : "\n\nVideo render için backend gerekli. Terminal: cd server && npm start")
                return
            }
        }

        statusMessage = "Video render için backend sunucusunu başlatın (Ayarlar → Backend)."
    }

    private func tryDirectScript(topic: String, duration: String, style: String) async -> String? {
        guard AIService.shared.hasAPIKey else { return nil }
        do {
            let text = try await AIService.shared.generateVideoScript(
                topic: topic, duration: duration, style: style
            )
            usedDirectOpenAI = true
            return text
        } catch {
            return nil
        }
    }

    private func friendlyNetworkError(_ error: Error) -> String {
        if let api = error as? APIError {
            switch api {
            case .invalidURL:
                return "Sunucu adresi geçersiz. Ayarlar → Backend URL kontrol edin."
            case .unauthorized:
                return "Oturum geçersiz. Ayarlar → Çıkış Yap → admin / 1234 ile tekrar giriş yapın (bulut hesabı)."
            case .server(let msg):
                if msg.lowercased().contains("incorrect api key") || msg.contains("sk-....") {
                    return """
                    OpenAI anahtarı Render'da geçersiz.

                    dashboard.render.com → ekinciler-api → Environment → OPENAI_API_KEY
                    Eski değeri silin, platform.openai.com'dan yeni sk- anahtarı yapıştırın, Save → redeploy bekleyin.
                    """
                }
                return msg
            case .network:
                if AppConfig.isAppStoreBuild {
                    return AppConfig.cloudUnavailableMessage
                }
                return """
                Sunucuya bağlanılamadı.

                Çözüm 1 — Backend başlatın:
                Terminal → cd server → npm start

                Çözüm 2 — OpenAI ile devam:
                Ayarlar → OpenAI anahtarını kaydedin
                """
            case .decoding:
                return "Sunucu yanıtı okunamadı."
            }
        }

        let msg = error.localizedDescription.lowercased()
        if msg.contains("connect") || msg.contains("bağlan") || msg.contains("network") {
            return AppConfig.isAppStoreBuild
                ? AppConfig.cloudUnavailableMessage
                : "Ağ hatası — sunucuya ulaşılamıyor. Backend (npm start) veya OpenAI anahtarı kontrol edin."
        }
        return error.localizedDescription
    }
}
