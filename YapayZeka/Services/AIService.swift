import Foundation

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int, String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API anahtarı tanımlı değil. Ayarlar bölümünden anahtarınızı girin."
        case .invalidResponse:
            return "Yapay zeka yanıtı işlenemedi."
        case .httpError(let code, let message):
            return "Sunucu hatası (\(code)): \(message)"
        case .network(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        }
    }
}

/// Merkezi OpenAI entegrasyonu — tüm modüller internet üzerinden AI kullanır.
final class AIService {
    static let shared = AIService()

    private let baseURL = "https://api.openai.com/v1"
    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        session = URLSession(configuration: config)
    }

    var hasAPIKey: Bool {
        guard let key = KeychainService.loadAPIKey() else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Chat

    func complete(
        system: String,
        user: String,
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7
    ) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": user]
        ]
        return try await chat(messages: messages, model: model, temperature: temperature)
    }

    func chat(
        messages: [[String: String]],
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7
    ) async throws -> String {
        guard let apiKey = KeychainService.loadAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Image (DALL-E)

    func generateImage(prompt: String, size: String = "1024x1024") async throws -> URL {
        guard let apiKey = KeychainService.loadAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": size,
            "quality": "standard"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)

        struct ImageResponse: Decodable {
            struct Item: Decodable { let url: String }
            let data: [Item]
        }
        let decoded = try decoder.decode(ImageResponse.self, from: data)
        guard let urlString = decoded.data.first?.url, let imageURL = URL(string: urlString) else {
            throw AIServiceError.invalidResponse
        }
        return imageURL
    }

    // MARK: - Domain prompts

    func generateAdCopy(product: String, platform: String, tone: String) async throws -> String {
        try await complete(
            system: """
            Sen profesyonel bir dijital pazarlama uzmanısın. Türkçe, etkileyici ve dönüşüm odaklı \
            reklam metinleri yaz. Hashtag, CTA ve emoji kullanımını platforma uygun ayarla.
            """,
            user: """
            Platform: \(platform)
            Ton: \(tone)
            Ürün/Hizmet: \(product)

            Şunları üret:
            1) Ana reklam metni (max 280 karakter)
            2) 3 alternatif başlık
            3) 8 hedefli hashtag
            4) CTA önerisi
            5) Hedef kitle önerisi
            """
        )
    }

    func generateCampaignPlan(budget: Double, audience: String, goal: String) async throws -> String {
        try await complete(
            system: "Sen Meta ve Google Ads kampanya stratejistisin. Türkçe, veriye dayalı öneriler sun.",
            user: """
            Bütçe: \(budget) TL
            Hedef kitle: \(audience)
            Kampanya hedefi: \(goal)

            Detaylı kampanya planı oluştur: günlük bütçe dağılımı, platform seçimi, \
            A/B test önerileri, KPI hedefleri ve optimizasyon takvimi.
            """
        )
    }

    func generateVideoScript(topic: String, duration: String, style: String) async throws -> String {
        try await complete(
            system: "Sen Reels/TikTok video senaristisin. Türkçe, kısa ve viral potansiyelli senaryolar yaz.",
            user: """
            Konu: \(topic)
            Süre: \(duration)
            Stil: \(style)

            Sahne sahne senaryo, ekran metinleri, müzik önerisi ve hook cümlesi üret.
            """
        )
    }

    func generateContentCalendar(brand: String, weeks: Int) async throws -> String {
        try await complete(
            system: "Sen sosyal medya içerik planlayıcısısın. Türkçe haftalık takvim formatında yanıt ver.",
            user: """
            Marka: \(brand)
            Süre: \(weeks) hafta

            Her gün için: platform, içerik türü (post/reels/story), konu başlığı ve kısa açıklama.
            Tablo benzeri düzenli formatta sun.
            """
        )
    }

    func generateWhatsAppReply(customerMessage: String, businessContext: String) async throws -> String {
        try await complete(
            system: """
            Sen profesyonel bir müşteri temsilcisisin. WhatsApp için kısa, nazik ve \
            çözüm odaklı Türkçe yanıtlar yaz. Gerekirse randevu teklif et.
            """,
            user: """
            İşletme bilgisi: \(businessContext)
            Müşteri mesajı: \(customerMessage)
            """
        )
    }

    func analyzeCompetitors(industry: String, competitors: String) async throws -> String {
        try await complete(
            system: "Sen dijital pazarlama analistisin. Rakip analizi ve fırsat haritası çıkar.",
            user: """
            Sektör: \(industry)
            Rakipler: \(competitors)

            SWOT, içerik stratejisi karşılaştırması ve viral fırsat önerileri sun.
            """
        )
    }

    func generateVoiceAdScript(product: String, voiceStyle: String) async throws -> String {
        try await complete(
            system: "Sen radyo ve dijital sesli reklam metin yazarısın. Türkçe, akıcı ve ikna edici metinler üret.",
            user: """
            Ürün: \(product)
            Ses tonu: \(voiceStyle)

            30 saniyelik sesli reklam metni, vurgu noktaları ve müzik/ses efekti önerileri yaz.
            """
        )
    }

    func generateAnalyticsInsight(metrics: String) async throws -> String {
        try await complete(
            system: "Sen performans pazarlama analistisin. Metrikleri yorumla ve aksiyon öner.",
            user: "Metrikler:\n\(metrics)\n\nTürkçe özet, trend analizi ve 5 iyileştirme önerisi sun."
        )
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String } ?? "Bilinmeyen hata"
            throw AIServiceError.httpError(http.statusCode, message)
        }
    }
}
