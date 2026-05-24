import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case server(String)
    case network(Error)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz sunucu adresi"
        case .unauthorized: return "Oturum süresi dolmuş. Tekrar giriş yapın."
        case .server(let msg): return msg
        case .network(let e): return "Ağ: \(e.localizedDescription)"
        case .decoding: return "Yanıt işlenemedi"
        }
    }
}

struct AuthResponse: Decodable {
    let token: String
    let user: AuthUser
}

struct AuthUser: Decodable {
    let id: String
    let username: String
    let email: String?
}

struct TextResponse: Decodable { let text: String }
struct ImageResponse: Decodable { let url: String }
struct VideoResponse: Decodable {
    let status: String?
    let videoUrl: String?
    let message: String?
}
struct HealthResponse: Decodable {
    let status: String
    let openai: Bool
    let meta: Bool
    let whatsapp: Bool
}
struct MetaOAuthStart: Decodable { let authUrl: String }
struct PublishResponse: Decodable {
    let ok: Bool?
    let simulated: Bool?
    let message: String?
    let postId: String?
}
struct WhatsAppSendResponse: Decodable {
    let ok: Bool?
    let text: String?
    let messageId: String?
}

struct TranslateResponse: Decodable {
    let language: String?
    let languageName: String?
    let translated: String
}

struct TranslateMultiResponse: Decodable {
    let translations: [String: String]
}

struct MetaOptimizeResponse: Decodable {
    let campaigns: [MetaAdCampaignItem]
    let aiPlan: String
}

struct CompetitorScanResponse: Decodable {
    let report: String
    let competitors: [CompetitorEntry]?
}

struct CompetitorAnalyzeResponse: Decodable {
    let report: String
    let competitor: CompetitorEntry?
}

struct WhatsAppBotSaveResponse: Decodable {
    let config: WhatsAppBotConfig
    let testReply: String?
    let message: String?
    let sent: Bool?
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> AuthResponse {
        try await post("/auth/login", body: ["username": username, "password": password], auth: false)
    }

    func register(username: String, password: String, email: String) async throws -> AuthResponse {
        try await post("/auth/register", body: ["username": username, "password": password, "email": email], auth: false)
    }

    // MARK: - Health

    func health() async throws -> HealthResponse {
        try await get("/health", auth: false)
    }

    // MARK: - AI

    func aiAdCopy(product: String, platform: String, tone: String) async throws -> String {
        let r: TextResponse = try await post("/ai/ad-copy", body: ["product": product, "platform": platform, "tone": tone])
        return r.text
    }

    func aiCampaignPlan(budget: Double, audience: String, goal: String) async throws -> String {
        let r: TextResponse = try await postJSON("/ai/campaign-plan", body: ["budget": budget, "audience": audience, "goal": goal])
        return r.text
    }

    func aiImage(prompt: String) async throws -> URL {
        let r: ImageResponse = try await post("/ai/image", body: ["prompt": prompt])
        guard let url = URL(string: r.url) else { throw APIError.decoding }
        return url
    }

    func aiVideoScript(topic: String, duration: String, style: String) async throws -> String {
        let r: TextResponse = try await post("/ai/video-script", body: ["topic": topic, "duration": duration, "style": style])
        return r.text
    }

    func aiVideoGenerate(prompt: String) async throws -> VideoResponse {
        try await post("/ai/video-generate", body: ["prompt": prompt])
    }

    func aiContentCalendar(brand: String, weeks: Int) async throws -> String {
        let r: TextResponse = try await postJSON("/ai/content-calendar", body: ["brand": brand, "weeks": weeks])
        return r.text
    }

    func aiWhatsAppReply(message: String, context: String) async throws -> String {
        let r: TextResponse = try await post("/ai/whatsapp-reply", body: ["message": message, "context": context])
        return r.text
    }

    func aiCompetitorAnalysis(industry: String, competitors: String) async throws -> String {
        let r: TextResponse = try await post("/ai/competitor-analysis", body: ["industry": industry, "competitors": competitors])
        return r.text
    }

    func aiVoiceAd(product: String, voiceStyle: String) async throws -> String {
        let r: TextResponse = try await post("/ai/voice-ad", body: ["product": product, "voiceStyle": voiceStyle])
        return r.text
    }

    func aiAnalyticsInsight(metrics: String) async throws -> String {
        let r: TextResponse = try await post("/ai/analytics-insight", body: ["metrics": metrics])
        return r.text
    }

    func aiChat(system: String, user: String) async throws -> String {
        let r: TextResponse = try await post("/ai/chat", body: ["system": system, "user": user])
        return r.text
    }

    // MARK: - CRUD

    func fetchCustomers() async throws -> [Customer] {
        try await get("/customers")
    }

    func createCustomer(_ customer: [String: String]) async throws -> Customer {
        try await post("/customers", body: customer)
    }

    func deleteCustomer(id: UUID) async throws {
        try await requestVoid("/customers/\(id.uuidString)", method: "DELETE")
    }

    func fetchPosts() async throws -> [ScheduledPost] {
        try await get("/scheduling")
    }

    func createPost(_ payload: [String: Any]) async throws -> ScheduledPost {
        try await postJSON("/scheduling", body: payload)
    }

    func fetchBrand() async throws -> BrandProfile {
        try await get("/brand")
    }

    func saveBrand(_ brand: BrandProfile) async throws -> BrandProfile {
        try await put("/brand", body: brand)
    }

    func fetchAnalytics() async throws -> AnalyticsSnapshot {
        try await get("/analytics")
    }

    func fetchSocialConnections() async throws -> [SocialConnection] {
        try await get("/social/connections")
    }

    func metaOAuthConfig() async throws -> MetaConfigInfo {
        try await get("/social/oauth/meta/config")
    }

    func startMetaOAuth() async throws -> URL {
        let r: MetaOAuthStart = try await get("/social/oauth/meta/start")
        guard let url = URL(string: r.authUrl) else { throw APIError.invalidURL }
        return url
    }

    func disconnectMeta() async throws {
        try await requestVoid("/social/oauth/meta", method: "DELETE")
    }

    func publishPost(platform: String, content: String, imageUrl: String?) async throws -> PublishResponse {
        var body: [String: Any] = ["platform": platform, "content": content]
        if let imageUrl { body["imageUrl"] = imageUrl }
        return try await postJSON("/social/publish", body: body)
    }

    func sendWhatsApp(to: String, message: String, customerMessage: String?, context: String?) async throws -> WhatsAppSendResponse {
        var body: [String: Any] = ["to": to, "message": message, "autoReply": customerMessage != nil]
        if let customerMessage { body["customerMessage"] = customerMessage }
        if let context { body["context"] = context }
        return try await postJSON("/whatsapp/send", body: body)
    }

    // MARK: - Future Features

    func futureStatus() async throws -> FutureFeatureStatus {
        try await get("/future/status")
    }

    func futureVideoRender(prompt: String, style: String) async throws -> VideoResponse {
        try await postJSON("/future/video/render", body: ["prompt": prompt, "style": style])
    }

    func futureVideoHistory() async throws -> [VideoHistoryItem] {
        try await get("/future/video/history")
    }

    func futureMetaCampaigns() async throws -> [MetaAdCampaignItem] {
        try await get("/future/meta-ads/campaigns")
    }

    func futureCreateMetaCampaign(name: String, budget: Double, objective: String) async throws -> MetaAdCampaignItem {
        try await postJSON("/future/meta-ads/campaigns", body: [
            "name": name, "budget": budget, "objective": objective,
        ])
    }

    func futureOptimizeMetaAds(totalBudget: Double) async throws -> MetaOptimizeResponse {
        try await postJSON("/future/meta-ads/optimize", body: ["totalBudget": totalBudget])
    }

    func futureWhatsAppBot() async throws -> WhatsAppBotConfig {
        try await get("/future/whatsapp/bot-config")
    }

    func futureSaveWhatsAppBot(
        enabled: Bool, greeting: String, hours: String,
        testPhone: String?, testMessage: String?
    ) async throws -> WhatsAppBotSaveResponse {
        var body: [String: Any] = [
            "enabled": enabled, "greeting": greeting, "businessHours": hours,
        ]
        if let testPhone { body["testPhone"] = testPhone }
        if let testMessage { body["testMessage"] = testMessage }
        return try await postJSON("/future/whatsapp/auto-reply", body: body)
    }

    func futureLanguages() async throws -> [LanguageOption] {
        try await get("/future/languages")
    }

    func futureTranslate(text: String, targetLang: String) async throws -> TranslateResponse {
        try await postJSON("/future/translate", body: ["text": text, "targetLang": targetLang])
    }

    func futureTranslateMulti(text: String, languages: [String]) async throws -> TranslateMultiResponse {
        try await postJSON("/future/translate", body: ["text": text, "multiLang": languages])
    }

    func futureCompetitors() async throws -> [CompetitorEntry] {
        try await get("/future/competitors")
    }

    func futureAddCompetitor(name: String, platform: String, handle: String, industry: String) async throws -> CompetitorEntry {
        try await postJSON("/future/competitors", body: [
            "name": name, "platform": platform, "handle": handle, "industry": industry,
        ])
    }

    func futureScanCompetitors(industry: String) async throws -> CompetitorScanResponse {
        try await postJSON("/future/competitors/scan", body: ["industry": industry])
    }

    func futureAnalyzeCompetitor(id: String, industry: String) async throws -> CompetitorAnalyzeResponse {
        try await postJSON("/future/competitors/\(id)/analyze", body: ["industry": industry])
    }

    func futurePlatforms() async throws -> PlatformSyncInfo {
        try await get("/future/platforms")
    }

    func futureSyncPlatforms() async throws -> PlatformSyncInfo {
        try await postJSON("/future/platforms/sync", body: ["action": "sync"])
    }

    // MARK: - HTTP helpers

    func requestVoid(_ path: String, method: String) async throws {
        guard BackendConfig.isConfigured, let url = URL(string: BackendConfig.baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = KeychainService.loadSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.server("Silme işlemi başarısız")
        }
    }

    private func get<T: Decodable>(_ path: String, auth: Bool = true) async throws -> T {
        try await request(path, method: "GET", body: nil as String?, auth: auth)
    }

    private func post<T: Decodable>(_ path: String, body: [String: String], auth: Bool = true) async throws -> T {
        try await request(path, method: "POST", body: body, auth: auth)
    }

    private func postJSON<T: Decodable>(_ path: String, body: [String: Any], auth: Bool = true) async throws -> T {
        guard BackendConfig.isConfigured, let url = URL(string: BackendConfig.baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = KeychainService.loadSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Sunucu hatası \(http.statusCode)"
            throw APIError.server(msg)
        }
        return try decoder.decode(T.self, from: data)
    }

    private func put<T: Decodable>(_ path: String, body: Encodable, auth: Bool = true) async throws -> T {
        try await request(path, method: "PUT", body: body, auth: auth)
    }

    private func request<T: Decodable, B: Encodable>(
        _ path: String,
        method: String,
        body: B?,
        auth: Bool
    ) async throws -> T {
        guard BackendConfig.isConfigured, let url = URL(string: BackendConfig.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = KeychainService.loadSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.decoding }

            if http.statusCode == 401 { throw APIError.unauthorized }

            if !(200...299).contains(http.statusCode) {
                let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Sunucu hatası \(http.statusCode)"
                throw APIError.server(msg)
            }

            return try decoder.decode(T.self, from: data)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error)
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: Any

    init(_ value: Any) { self.value = value }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as String: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [String: String]:
            try container.encode(v)
        case let v as [String: Any]:
            let data = try JSONSerialization.data(withJSONObject: v)
            let obj = try JSONSerialization.jsonObject(with: data)
            try encodeAny(obj, container: &container)
        default:
            if let enc = value as? Encodable {
                try enc.encode(to: encoder)
            } else {
                throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "Unsupported type"))
            }
        }
    }

    private func encodeAny(_ obj: Any, container: inout SingleValueEncodingContainer) throws {
        switch obj {
        case let v as String: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: obj))
        }
    }
}

private struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws { value = "" }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as String: try c.encode(v)
        case let v as Int: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as Bool: try c.encode(v)
        default: try c.encode(String(describing: value))
        }
    }
}
