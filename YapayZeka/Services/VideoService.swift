import Foundation
import Combine
import Photos
import UIKit

@MainActor
final class VideoService: ObservableObject {
    static let shared = VideoService()

    @Published var isLoading = false
    @Published var script = ""
    @Published var videoURL: URL?
    @Published var localFileURL: URL?
    @Published var statusMessage = ""
    @Published var error: String?
    @Published var usedDirectOpenAI = false
    @Published var isSimulatedVideo = false
    @Published var library: [VideoLibraryItem] = []
    @Published var isDownloading = false
    @Published var downloadMessage: String?

    private static let libraryKey = "ekinciler.video.library"
    private var lastPrompt = ""

    private init() {
        loadLibrary()
    }

    static func videosDirectory() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func syncHistoryFromServer() async {
        guard BackendConfig.useBackend else { return }
        do {
            let remote = try await APIClient.shared.futureVideoHistory()
            mergeRemoteHistory(remote)
        } catch {
            // Sessiz — yerel liste kalır
        }
    }

    func downloadCurrentVideo() async {
        guard let remote = videoURL else {
            downloadMessage = "İndirilecek video yok."
            return
        }
        isDownloading = true
        downloadMessage = nil
        defer { isDownloading = false }
        do {
            let local = try await downloadFile(from: remote)
            localFileURL = local
            if let idx = library.firstIndex(where: { $0.remoteURLString == remote.absoluteString }) {
                library[idx].localFileName = local.lastPathComponent
            }
            saveLibrary()
            downloadMessage = "✓ Video indirildi. Galeri veya Paylaş kullanabilirsiniz."
        } catch {
            downloadMessage = "İndirme hatası: \(error.localizedDescription)"
        }
    }

    func selectLibraryItem(_ item: VideoLibraryItem) async {
        script = item.prompt
        videoURL = item.remoteURL
        localFileURL = item.localURL
        isSimulatedVideo = item.status == "simulated"
        if item.remoteURL != nil && item.localURL == nil {
            await downloadCurrentVideo()
        }
    }

    func saveToPhotoLibrary(fileURL: URL) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            downloadMessage = "Fotoğraflar izni gerekli. Ayarlar → Ekinciler AI → Fotoğraflar."
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }
            downloadMessage = "✓ Video Fotoğraflar’a kaydedildi."
        } catch {
            downloadMessage = "Galeri kaydı başarısız: \(error.localizedDescription)"
        }
    }

    func openInFiles(fileURL: URL) {
        // Dosya zaten Documents/Videos içinde — kullanıcı Dosyalar uygulamasından erişir
        downloadMessage = "Dosya: \(fileURL.lastPathComponent) (Dosyalar → iPhone’um → Ekinciler AI)"
    }

    private func downloadFile(from remote: URL) async throws -> URL {
        let (temp, _) = try await URLSession.shared.download(from: remote)
        let name = "video-\(UUID().uuidString).mp4"
        let dest = Self.videosDirectory().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: temp, to: dest)
        return dest
    }

    private func registerInLibrary(prompt: String, remote: URL?, status: String?) {
        let entry = VideoLibraryItem(
            id: UUID().uuidString,
            prompt: prompt,
            remoteURLString: remote?.absoluteString,
            localFileName: nil,
            status: status,
            createdAt: Date()
        )
        library.removeAll { $0.remoteURLString == entry.remoteURLString && entry.remoteURLString != nil }
        library.insert(entry, at: 0)
        library = Array(library.prefix(30))
        saveLibrary()
    }

    private func mergeRemoteHistory(_ items: [VideoHistoryItem]) {
        for item in items {
            if library.contains(where: { $0.id == item.id }) { continue }
            library.append(VideoLibraryItem(
                id: item.id,
                prompt: item.prompt ?? "Video",
                remoteURLString: item.videoUrl,
                localFileName: nil,
                status: item.status,
                createdAt: ISO8601DateFormatter().date(from: item.createdAt ?? "") ?? Date()
            ))
        }
        library.sort { $0.createdAt > $1.createdAt }
        library = Array(library.prefix(30))
        saveLibrary()
    }

    private func loadLibrary() {
        guard let data = UserDefaults.standard.data(forKey: Self.libraryKey),
              let decoded = try? JSONDecoder().decode([VideoLibraryItem].self, from: data) else { return }
        library = decoded.filter { $0.hasLocalFile || $0.remoteURL != nil }
    }

    private func saveLibrary() {
        if let data = try? JSONEncoder().encode(library) {
            UserDefaults.standard.set(data, forKey: Self.libraryKey)
        }
    }

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
        localFileURL = nil
        isSimulatedVideo = false
        downloadMessage = nil
        lastPrompt = trimmed
        defer { isLoading = false }

        if BackendConfig.useBackend {
            do {
                let result = try await APIClient.shared.aiVideoGenerate(prompt: trimmed)
                isSimulatedVideo = result.status == "simulated"
                statusMessage = result.message ?? result.status ?? "Video işlendi"
                if let plan = result.productionPlan, !plan.isEmpty {
                    script = trimmed + "\n\n——— ÇEKİM PLANI ———\n" + plan
                }
                if let urlString = result.videoUrl, let url = URL(string: urlString) {
                    videoURL = url
                    registerInLibrary(prompt: trimmed, remote: url, status: result.status)
                } else {
                    registerInLibrary(prompt: trimmed, remote: nil, status: result.status ?? "simulated")
                }
                await syncHistoryFromServer()
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
