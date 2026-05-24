import Foundation
import Combine

@MainActor
final class FutureFeaturesManager: ObservableObject {
    static let shared = FutureFeaturesManager()

    @Published var status: FutureFeatureStatus?
    @Published var videoHistory: [VideoHistoryItem] = []
    @Published var metaCampaigns: [MetaAdCampaignItem] = []
    @Published var competitors: [CompetitorEntry] = []
    @Published var languages: [LanguageOption] = []
    @Published var whatsappBot = WhatsAppBotConfig(enabled: false, greeting: "Merhaba!", businessHours: "09:00-18:00")
    @Published var platformSync: PlatformSyncInfo?
    @Published var isLoading = false
    @Published var lastResult = ""
    @Published var lastError: String?

    private init() {}

    func refreshAll() async {
        guard BackendConfig.useBackend else {
            loadLocalDefaults()
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            async let s: FutureFeatureStatus = APIClient.shared.futureStatus()
            async let v: [VideoHistoryItem] = APIClient.shared.futureVideoHistory()
            async let m: [MetaAdCampaignItem] = APIClient.shared.futureMetaCampaigns()
            async let c: [CompetitorEntry] = APIClient.shared.futureCompetitors()
            async let l: [LanguageOption] = APIClient.shared.futureLanguages()
            async let w: WhatsAppBotConfig = APIClient.shared.futureWhatsAppBot()
            async let p: PlatformSyncInfo = APIClient.shared.futurePlatforms()

            status = try await s
            videoHistory = try await v
            metaCampaigns = try await m
            competitors = try await c
            languages = try await l
            whatsappBot = try await w
            platformSync = try await p
        } catch {
            lastError = error.localizedDescription
            loadLocalDefaults()
        }
    }

    func renderVideo(prompt: String, style: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            if BackendConfig.useBackend {
                let r = try await APIClient.shared.futureVideoRender(prompt: prompt, style: style)
                lastResult = r.message ?? r.status ?? "Video işlendi"
                videoHistory = (try? await APIClient.shared.futureVideoHistory()) ?? videoHistory
            } else {
                await VideoService.shared.generateVideo(prompt: "\(prompt). \(style)")
                lastResult = VideoService.shared.statusMessage
            }
        } catch {
            await VideoService.shared.generateVideo(prompt: prompt)
            lastResult = VideoService.shared.statusMessage.isEmpty ? error.localizedDescription : VideoService.shared.statusMessage
        }
    }

    func createMetaCampaign(name: String, budget: Double, objective: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if BackendConfig.useBackend {
                let c = try await APIClient.shared.futureCreateMetaCampaign(name: name, budget: budget, objective: objective)
                metaCampaigns.insert(c, at: 0)
                lastResult = c.message ?? "Kampanya oluşturuldu"
            } else {
                let local = MetaAdCampaignItem(id: UUID().uuidString, name: name, budget: budget, objective: objective, status: "ACTIVE", simulated: true, message: "Yerel mod", createdAt: ISO8601DateFormatter().string(from: Date()))
                metaCampaigns.insert(local, at: 0)
                lastResult = "Kampanya yerel olarak oluşturuldu"
            }
        } catch { lastError = error.localizedDescription }
    }

    func optimizeMetaAds(totalBudget: Double) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let r = try await APIClient.shared.futureOptimizeMetaAds(totalBudget: totalBudget)
            metaCampaigns = r.campaigns
            lastResult = r.aiPlan
        } catch { lastError = error.localizedDescription }
    }

    func saveWhatsAppBot(enabled: Bool, greeting: String, hours: String, testPhone: String?, testMessage: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let r = try await APIClient.shared.futureSaveWhatsAppBot(
                enabled: enabled, greeting: greeting, hours: hours,
                testPhone: testPhone, testMessage: testMessage
            )
            whatsappBot = r.config
            lastResult = r.testReply ?? r.message ?? "Bot kaydedildi"
        } catch { lastError = error.localizedDescription }
    }

    func translate(text: String, lang: String, multi: [String]?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if BackendConfig.useBackend {
                if let multi, multi.count > 1 {
                    let r = try await APIClient.shared.futureTranslateMulti(text: text, languages: multi)
                    lastResult = r.translations.map { "\($0.key): \($0.value)" }.joined(separator: "\n\n")
                } else {
                    let r = try await APIClient.shared.futureTranslate(text: text, targetLang: lang)
                    lastResult = r.translated
                }
            } else {
                lastResult = try await AIService.shared.complete(
                    system: "Profesyonel çevirmensin.",
                    user: "Metni \(lang) diline çevir:\n\(text)"
                )
            }
        } catch { lastError = error.localizedDescription }
    }

    func addCompetitor(name: String, platform: String, handle: String, industry: String) async {
        do {
            let c = try await APIClient.shared.futureAddCompetitor(name: name, platform: platform, handle: handle, industry: industry)
            competitors.append(c)
        } catch { lastError = error.localizedDescription }
    }

    func scanCompetitors(industry: String) async {
        isLoading = true
        defer { isLoading = false }
        let names = competitors.map(\.name).joined(separator: ", ")
        do {
            if BackendConfig.useBackend {
                let r = try await APIClient.shared.futureScanCompetitors(industry: industry)
                lastResult = r.report
            } else {
                lastResult = try await AIService.shared.analyzeCompetitors(industry: industry, competitors: names)
            }
        } catch { lastError = error.localizedDescription }
    }

    func analyzeCompetitor(id: String, industry: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let r = try await APIClient.shared.futureAnalyzeCompetitor(id: id, industry: industry)
            lastResult = r.report
        } catch { lastError = error.localizedDescription }
    }

    func syncPlatforms() async {
        isLoading = true
        defer { isLoading = false }
        do {
            platformSync = try await APIClient.shared.futureSyncPlatforms()
            lastResult = platformSync?.lastSyncMessage ?? "Senkronizasyon tamamlandı"
        } catch { lastError = error.localizedDescription }
    }

    private func loadLocalDefaults() {
        languages = [
            LanguageOption(code: "tr", name: "Türkçe"),
            LanguageOption(code: "en", name: "English"),
            LanguageOption(code: "de", name: "Deutsch"),
            LanguageOption(code: "fr", name: "Français"),
            LanguageOption(code: "es", name: "Español"),
        ]
    }
}
