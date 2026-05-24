import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var apiKeyInput: String = ""
    @Published var hasValidAPIKey: Bool = false
    @Published var lastAIStatus: String = "Hazır"

    private init() {
        refreshAPIKeyStatus()
    }

    func refreshAPIKeyStatus() {
        hasValidAPIKey = AIService.shared.hasAPIKey
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastAIStatus = "Anahtar boş olamaz"
            return
        }
        guard trimmed.hasPrefix("sk-") else {
            lastAIStatus = "Geçersiz format — anahtar sk- ile başlamalı"
            return
        }
        if KeychainService.saveAPIKey(trimmed) {
            apiKeyInput = ""
            hasValidAPIKey = true
            lastAIStatus = "OpenAI bağlandı ✓"
        } else {
            lastAIStatus = "Kayıt başarısız"
        }
    }

    func removeAPIKey() {
        KeychainService.deleteAPIKey()
        hasValidAPIKey = false
        lastAIStatus = "API anahtarı silindi"
    }
}
